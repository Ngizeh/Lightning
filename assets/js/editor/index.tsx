import React from 'react';
import { createRoot } from "react-dom/client";
import Editor from './Editor';

interface EditorEntrypoint {
  componentRoot: ReturnType<typeof createRoot> | null;
  destroyed(): void;
  el: HTMLElement;
  field: HTMLTextAreaElement;
  handleContentChange(content: string): void;
  mounted(): void;
  observer: MutationObserver | null;
  render(): void;
  setupObserver(): void;
}

let EditorComponent: typeof Editor | undefined;

export default {
  mounted(this: EditorEntrypoint) {
    import('./Editor').then((module) => {
      EditorComponent = module.default as typeof Editor;
      this.field = this.el.children[0] as HTMLTextAreaElement;

      // Hide the default text box
      this.field.style.display = "none";
      
      // Insert a new div for the live editor
      const root = document.createElement("div");
      root.style.height="100%";
      this.el.appendChild(root)
      this.componentRoot = createRoot(root);
      
      
      this.setupObserver()
      this.render();
    });
  },
  handleContentChange(content: string) {
    if (this.field) {
      this.field.value = content
    }
  },
  render() {
    const { adaptor } = this.el.dataset;
    const source = this.field.value;
    if (EditorComponent) {
      this.componentRoot?.render(
        <EditorComponent
          adaptor={adaptor}
          source={source}
          onChange={(src) => this.handleContentChange(src)}
      />);
    }
  },
  setupObserver() {
    this.observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (
          mutation.type === "attributes" &&
          mutation.attributeName == "data-adaptor"
        ) {
          this.render()
        }
      });
    });

    this.observer.observe(this.el, { attributes: true });
  },
  destroyed() {
    this.componentRoot?.unmount();
    this.observer?.disconnect();
  }
} as EditorEntrypoint