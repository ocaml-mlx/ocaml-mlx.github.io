const main = document.querySelector("#content");
if (main && main.childElementCount === 0) {
  const url = new URL(location.href);
  url.searchParams.set("_mlx", "455baf288635");
  if (url.href !== location.href) location.replace(url.href);
} else {
  await import("/app.455baf288635.js");
}
