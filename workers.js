const OWNER = "cc150";
const REPO = "files-share";
const TOKEN = ""; // 如果是私有仓库，填入你的 GitHub Token，公开仓库留空即可

addEventListener("fetch", (event) => {
  event.respondWith(handleRequest(event.request));
});

/**
 * 将字符串安全地转义为 HTML 实体，防止 XSS
 */
function escapeHtml(str) {
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

/**
 * 格式化文件大小，返回可读字符串
 */
function formatSize(bytes) {
  if (bytes == null || isNaN(bytes)) return "-";
  if (bytes < 1024) return bytes + " B";
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(2) + " KB";
  return (bytes / (1024 * 1024)).toFixed(2) + " MB";
}

/**
 * 规范化路径，防止路径遍历攻击，去除尾部斜杠
 */
function normalizePath(rawPath) {
  let p = rawPath.replace(/^\/+/, ""); // 去掉前导斜杠
  // 只保留字母、数字、-、_、.、/，丢弃 .. 等危险片段
  p = p
    .split("/")
    .filter((seg) => seg !== ".." && /^[a-zA-Z0-9\-_.]+$/.test(seg))
    .join("/");
  return p ? "/" + p : "/";
}

/**
 * 生成安全的路由链接
 */
function linkHref(currentPath, name) {
  if (currentPath === "/") return "/" + name;
  return currentPath + "/" + name;
}

async function handleRequest(request) {
  try {
    const url = new URL(request.url);
    let path = normalizePath(url.pathname);

    // 构造 GitHub API 请求
    const apiUrl = `https://api.github.com/repos/${OWNER}/${REPO}/contents${path}`;

    const headers = {
      "User-Agent": "Cloudflare-Worker-Directory-Lister",
    };
    if (TOKEN) {
      headers["Authorization"] = `token ${TOKEN}`;
    }

    const res = await fetch(apiUrl, { headers });

    // 统一错误处理，不泄露内部细节
    if (!res.ok) {
      return new Response(
        `<h1>错误 ${res.status}</h1><p>目录不存在或请求被拒绝。</p>`,
        {
          status: res.status === 404 ? 404 : 403,
          headers: { "Content-Type": "text/html; charset=utf-8" },
        }
      );
    }

    const data = await res.json();

    // 如果用户请求的是具体文件，通过 Worker 代理下载（流量走 Cloudflare）
    // 大文件优先走 raw 直链，小文件走代理缓存
    if (!Array.isArray(data)) {
      const rawRes = await fetch(data.download_url, { headers });
      if (!rawRes.ok) {
        return new Response(
          `<h1>错误 ${rawRes.status}</h1><p>文件下载失败。</p>`,
          {
            status: 502,
            headers: { "Content-Type": "text/html; charset=utf-8" },
          }
        );
      }
      const blob = await rawRes.blob();
      return new Response(blob, {
        status: rawRes.status,
        headers: {
          "Content-Type": rawRes.headers.get("Content-Type") || "application/octet-stream",
          "Content-Length": blob.size,
          "Content-Disposition": `attachment; filename="${escapeHtml(data.name)}"`,
          "Cache-Control": "public, max-age=3600",  // 文件缓存 1 小时
        },
      });
    }

    // 如果是目录，生成类似文件管理器的 HTML 页面
    let fileRows = "";
    // 如果不在根目录，加上"返回上级"
    if (path !== "/") {
      const parentPath = path.split("/").slice(0, -1).join("/") || "/";
      fileRows += `<tr><td>📁 <a href="${escapeHtml(parentPath)}">.. (返回上级)</a></td><td>-</td></tr>`;
    }

    for (const item of data) {
      const icon = item.type === "dir" ? "📁" : "📄";
      const href = linkHref(path, item.name);
      fileRows += `<tr><td>${icon} <a href="${escapeHtml(href)}">${escapeHtml(item.name)}</a></td><td>${formatSize(item.size)}</td></tr>`;
    }

    const safePath = escapeHtml(path);
    const html = `<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Index of ${safePath}</title>
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
<h1>文件索引目录: ${safePath}</h1>
<table>
<thead><tr><th>名称</th><th>大小</th></tr></thead>
<tbody>${fileRows}</tbody>
</table>
</body>
</html>`;

    return new Response(html, {
      headers: {
        "Content-Type": "text/html; charset=utf-8",
        "Cache-Control": "public, max-age=300",
        "X-Content-Type-Options": "nosniff",
        "X-Frame-Options": "DENY",
        "X-XSS-Protection": "1; mode=block",
      },
    });
  } catch (err) {
    // 捕获所有未预期的错误，返回 500
    return new Response(
      "<h1>服务器错误</h1><p>请稍后重试。</p>",
      { status: 500, headers: { "Content-Type": "text/html;charset=UTF-8" } }
    );
  }
}
