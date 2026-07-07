// Download hook for handling PDF file downloads
export const DownloadHook = {
  mounted() {
    this.handleEvent("download", ({ url, filename }) => {
      // Create a temporary anchor element
      const link = document.createElement("a");
      link.href = url;
      link.download = filename;
      link.style.display = "none";

      // Append to body, trigger click, then remove
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);

      console.log(`Downloaded: ${filename}`);
    });
  },
};

export default DownloadHook;
