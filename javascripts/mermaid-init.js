// Init mermaid for Material for MkDocs (works with navigation.instant SPA).
if (typeof mermaid !== "undefined") {
  mermaid.initialize({ startOnLoad: false, theme: "default" });
  if (typeof document$ !== "undefined") {
    document$.subscribe(() => {
      mermaid.run({ querySelector: ".mermaid" });
    });
  } else {
    document.addEventListener("DOMContentLoaded", () => {
      mermaid.run({ querySelector: ".mermaid" });
    });
  }
}
