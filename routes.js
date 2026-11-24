export const documentationPaths = {
  installation: "/docs/",
  syntax: "/docs/jsx-syntax/",
  "how-it-works": "/docs/how-it-works/",
  agents: "/docs/for-your-agent/",
  editors: "/docs/editor-support/",
  ecosystem: "/docs/ecosystem/",
  libraries: "/docs/libraries/"
};

export const articlePaths = {
  "hello-world": "/blog/hello-world/",
  "melange-playground": "/blog/melange-playground/",
  "fragments-0-12": "/blog/fragments-0-12/",
  "ocaml-5-4": "/blog/ocaml-5-4/"
};

export function documentationUrl(topicAndFragment) {
  const separator = topicAndFragment.indexOf("#");
  const key = separator === -1 ? topicAndFragment : topicAndFragment.slice(0, separator);
  if (!Object.hasOwn(documentationPaths, key)) {
    throw new RangeError(`Unknown documentation topic: ${key}`);
  }
  return documentationPaths[key] + (separator === -1 ? "" : topicAndFragment.slice(separator));
}

export function legacyLocation(search, hash) {
  const params = new URLSearchParams(search);
  const page = params.get("page");
  if (!["landing", "docs", "blog"].includes(page)) return null;

  let path = "/";
  if (page === "docs") {
    const topic = params.get("topic");
    path = Object.hasOwn(documentationPaths, topic) ? documentationPaths[topic] : documentationPaths.installation;
  } else if (page === "blog") {
    const article = params.get("article");
    path = Object.hasOwn(articlePaths, article) ? articlePaths[article] : "/blog/";
  }

  params.delete("page");
  params.delete("topic");
  params.delete("article");
  const query = params.toString();
  return path + (query ? `?${query}` : "") + hash;
}
