defmodule Captablex.Waterfall do
  @moduledoc """
  The Waterfall context handles liquidation waterfall calculations.

  This module computes how exit proceeds are distributed among stockholders
  based on their stock class preferences, participation rights, and seniority.
  """

  import Ecto.Query
  alias Captablex.Repo
  alias Captablex.CapTable.StockClass
  alias Captablex.{SecurityIssuance, Stakeholder}

  @doc """
  Calculates the liquidation waterfall for a given exit value.

  Returns a list of distributions showing how proceeds flow to each stakeholder.

  ## Parameters
    - exit_value: Total exit proceeds (e.g., $10,000,000)

  ## Returns
    A map with:
    - :total_exit_value - The exit value provided
    - :distributions - List of %{stakeholder_id, stakeholder_name, amount, breakdown}
    - :remaining_proceeds - Any undistributed proceeds
    - :waterfall_steps - Detailed step-by-step breakdown

  ## Examples

      iex> calculate_waterfall(10_000_000)
      %{
        total_exit_value: 10_000_000,
        distributions: [
          %{stakeholder_id: 1, stakeholder_name: "Investor A", amount: 5_000_000, ...},
          %{stakeholder_id: 2, stakeholder_name: "Founder", amount: 3_000_000, ...}
        ],
        remaining_proceeds: 2_000_000,
        waterfall_steps: [...]
      }
  """
  def calculate_waterfall(exit_value) when is_number(exit_value) and exit_value > 0 do
    # Step 1: Load all securities with their stock classes and stakeholders
    securities = load_securities_with_details()

    # Step 2: Group securities by seniority rank (higher rank = paid first)
    securities_by_seniority = group_by_seniority(securities)

    # Step 3: Calculate total outstanding shares for pro-rata calculations
    total_shares = calculate_total_shares(securities)

    # Step 4: Process waterfall in seniority order
    {distributions, remaining_proceeds, steps} =
      process_waterfall(securities_by_seniority, exit_value, total_shares)

    %{
      total_exit_value: exit_value,
      distributions: consolidate_distributions(distributions),
      remaining_proceeds: remaining_proceeds,
      waterfall_steps: steps,
      total_distributed: exit_value - remaining_proceeds
    }
  end

  defp load_securities_with_details do
    from(s in SecurityIssuance,
      join: sc in StockClass,
      on: s.stock_class_id == sc.id,
      join: sh in Stakeholder,
      on: s.stakeholder_id == sh.id,
      select: %{
        security_id: s.id,
        stakeholder_id: sh.id,
        stakeholder_name: sh.name,
        shares: s.shares,
        stock_class_id: sc.id,
        stock_class_name: fragment("? || ' - ' || ?", sc.security_type, sc.series),
        security_type: sc.security_type,
        series: sc.series,
        liquidation_preference_multiple: sc.liquidation_preference_multiple,
        participation_type: sc.participation_type,
        seniority_rank: sc.seniority_rank,
        price_per_share: sc.price_per_share
      }
    )
    |> Repo.all()
  end

  defp group_by_seniority(securities) do
    securities
    |> Enum.group_by(& &1.seniority_rank)
    |> Enum.sort_by(fn {rank, _securities} -> rank end, :desc)
  end

  defp calculate_total_shares(securities) do
    Enum.reduce(securities, 0, fn sec, acc -> acc + sec.shares end)
  end

  defp process_waterfall(securities_by_seniority, initial_proceeds, total_shares) do
    {distributions, remaining, steps} =
      Enum.reduce(
        securities_by_seniority,
        {[], initial_proceeds, []},
        fn {rank, securities}, {dist_acc, proceeds_acc, steps_acc} ->
          # Process this seniority tier
          {tier_distributions, tier_remaining, tier_steps} =
            process_seniority_tier(rank, securities, proceeds_acc, total_shares)

          {
            dist_acc ++ tier_distributions,
            tier_remaining,
            steps_acc ++ tier_steps
          }
        end
      )

    {distributions, remaining, steps}
  end

  defp process_seniority_tier(rank, securities, available_proceeds, total_shares) do
    # Step 1: Calculate liquidation preferences for this tier
    tier_preferences =
      Enum.map(securities, fn sec ->
        preference_amount = calculate_preference_amount(sec)

        %{
          security: sec,
          preference_amount: preference_amount,
          shares: sec.shares
        }
      end)

    total_tier_preference =
      Enum.reduce(tier_preferences, 0, fn pref, acc ->
        acc + pref.preference_amount
      end)

    # Step 2: Pay out liquidation preferences
    {preference_distributions, proceeds_after_preferences} =
      if total_tier_preference > 0 do
        pay_liquidation_preferences(tier_preferences, available_proceeds, rank)
      else
        {[], available_proceeds}
      end

    # Step 3: Handle participation (if any securities are participating)
    {participation_distributions, final_proceeds} =
      pay_participation(securities, proceeds_after_preferences, total_shares, rank)

    # Combine distributions
    all_distributions = preference_distributions ++ participation_distributions

    step = %{
      seniority_rank: rank,
      type: "tier_#{rank}",
      total_preference: total_tier_preference,
      proceeds_in: available_proceeds,
      proceeds_out: final_proceeds,
      distributions: all_distributions
    }

    {all_distributions, final_proceeds, [step]}
  end

  defp calculate_preference_amount(security) do
    # Preference = shares * price_per_share * liquidation_preference_multiple
    price = security.price_per_share || Decimal.new(0)
    multiple = security.liquidation_preference_multiple || Decimal.new(1)
    shares = Decimal.new(security.shares)

    Decimal.mult(Decimal.mult(shares, price), multiple)
    |> Decimal.to_float()
  end

  defp pay_liquidation_preferences(tier_preferences, available_proceeds, rank) do
    total_preference =
      Enum.reduce(tier_preferences, 0, fn pref, acc ->
        acc + pref.preference_amount
      end)

    # If we have enough to pay all preferences, pay them in full
    # Otherwise, prorate across the tier
    distributions =
      if available_proceeds >= total_preference do
        # Pay full preferences
        Enum.map(tier_preferences, fn pref ->
          %{
            stakeholder_id: pref.security.stakeholder_id,
            stakeholder_name: pref.security.stakeholder_name,
            amount: pref.preference_amount,
            type: :liquidation_preference,
            seniority_rank: rank,
            stock_class: pref.security.stock_class_name,
            shares: pref.security.shares
          }
        end)
      else
        # Prorate available proceeds across preferences
        prorate_factor =
          if total_preference > 0, do: available_proceeds / total_preference, else: 0

        Enum.map(tier_preferences, fn pref ->
          prorated_amount = pref.preference_amount * prorate_factor

          %{
            stakeholder_id: pref.security.stakeholder_id,
            stakeholder_name: pref.security.stakeholder_name,
            amount: prorated_amount,
            type: :liquidation_preference_prorated,
            seniority_rank: rank,
            stock_class: pref.security.stock_class_name,
            shares: pref.security.shares
          }
        end)
      end

    total_paid = Enum.reduce(distributions, 0, fn d, acc -> acc + d.amount end)
    remaining = max(0, available_proceeds - total_paid)

    {distributions, remaining}
  end

  defp pay_participation(securities, available_proceeds, total_shares, rank) do
    # Only participating preferred gets to participate in remaining proceeds
    participating_securities =
      Enum.filter(securities, fn sec ->
        sec.participation_type == "participating"
      end)

    if participating_securities == [] or available_proceeds <= 0 do
      # No participation, proceed to next tier
      {[], available_proceeds}
    else
      # Calculate pro-rata share for participating securities
      participating_shares =
        Enum.reduce(participating_securities, 0, fn sec, acc ->
          acc + sec.shares
        end)

      distributions =
        Enum.map(participating_securities, fn sec ->
          pro_rata_share = if total_shares > 0, do: sec.shares / total_shares, else: 0
          participation_amount = available_proceeds * pro_rata_share

          %{
            stakeholder_id: sec.stakeholder_id,
            stakeholder_name: sec.stakeholder_name,
            amount: participation_amount,
            type: :participation,
            seniority_rank: rank,
            stock_class: sec.stock_class_name,
            shares: sec.shares
          }
        end)

      total_paid = Enum.reduce(distributions, 0, fn d, acc -> acc + d.amount end)
      remaining = max(0, available_proceeds - total_paid)

      {distributions, remaining}
    end
  end

  defp consolidate_distributions(distributions) do
    # Group by stakeholder and sum amounts
    distributions
    |> Enum.group_by(& &1.stakeholder_id)
    |> Enum.map(fn {stakeholder_id, stakeholder_distributions} ->
      total_amount = Enum.reduce(stakeholder_distributions, 0, fn d, acc -> acc + d.amount end)
      first = hd(stakeholder_distributions)

      %{
        stakeholder_id: stakeholder_id,
        stakeholder_name: first.stakeholder_name,
        total_amount: total_amount,
        breakdown: stakeholder_distributions
      }
    end)
    |> Enum.sort_by(& &1.total_amount, :desc)
  end
end
