const OWNER = "cc150";
const REPO = "files-share";
const TOKEN = ""; // 如果是私有仓库，填入你的 GitHub Token，公开仓库留空即可

addEventListener("fetch", (event) => {
  event.respondWith(handleRequest(event.request));
});

async function handleRequest(request) {
  const url = new URL(request.url);
  let path = url.pathname;

  // 构造 GitHub API 请求
  const apiGen = `https://api.github.com/repos/${OWNER}/${REPO}/contents${path}`;

  const headers = {
    "User-Agent": "Cloudflare-Worker-Directory-Lister",
  };
  if (TOKEN) {
    headers["Authorization"] = `token ${TOKEN}`;
  }

  const res = await fetch(apiGen, { headers });

  if (res.status !== 200) {
    return new Response("目录不存在或触发API限制", { status: res.status });
  }

  const data = await res.json();

  // 如果用户请求的是具体文件，直接去拿原始文件内容（或者重定向到 raw 链接）
  if (!Array.isArray(data)) {
    return fetch(data.download_url);
  }

  // 如果是目录，生成类似文件管理器的 HTML 页面
  let fileRows = "";
  // 如果不在根目录，加上“返回上级”
  if (path !== "/") {
    const parentPath = path.split("/").slice(0, -1).join("/") || "/";
    fileRows += `<tr><td>📁 <a href="${parentPath}">.. (返回上级)</a></td><td>-</td></tr>`;
  }

  data.forEach((item) => {
    const icon = item.type === "dir" ? "📁" : "📄";
    const fileSize =
      item.type === "dir" ? "-" : (item.size / 1024).toFixed(2) + " KB";
    fileRows += `
      <tr>
        <td>${icon} <a href="${path === "/" ? "" : path}/${item.name}">${item.name}</a></td>
        <td>${fileSize}</td>
      </tr>
    `;
  });

  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Index of ${path}</title>
      <style>
        body { font-family: monospace; padding: 20px; background: #f4f4f9; color: #333; }
        h1 { font-size: 1.5em; border-bottom: 1px solid #ccc; padding-bottom: 10px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; background: #fff; box-shadow: 0 2px 5px rgba(0,0,0,0.05); }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #eee; }
        th { background: #f0f0f0; }
        a { color: #0066cc; text-decoration: none; }
        a:hover { text-decoration: underline; }
      </style>
    </head>
    <body>
      <h1>文件索引目录: ${path}</h1>
      <table>
        <thead>
          <tr><th>名称</th><th>大小</th></tr>
        </thead>
        <tbody>
          ${fileRows}
        </tbody>
      </table>
    </body>
    </html>
  `;

  return new Response(html, {
    headers: { "Content-Type": "text/html;charset=UTF-8" },
  });
}
