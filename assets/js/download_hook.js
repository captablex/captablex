export const DownloadHook = {
  mounted() {
    this.handleEvent("download", ({ filename, content, mime_type }) => {
      // Create a blob from the content
      const blob = new Blob([content], { type: mime_type });

      // Create a temporary URL for the blob
      const url = window.URL.createObjectURL(blob);

      // Create a temporary anchor element to trigger download
      const a = document.createElement("a");
      a.href = url;
      a.download = filename;
      document.body.appendChild(a);

      // Trigger the download
      a.click();

      // Clean up
      document.body.removeChild(a);
      window.URL.revokeObjectURL(url);

      console.log(`Downloaded: ${filename}`);
    });
  },
};
