import sys
import os
import socket
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import mimetypes

mimetypes.add_type("application/wasm", ".wasm")
mimetypes.add_type("application/octet-stream", ".pck")
mimetypes.add_type("application/javascript", ".js")
mimetypes.add_type("text/html", ".html")

class GodotWebHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()

    def log_message(self, format, *args):
        sys.stdout.write(f"[{self.log_date_time_string()}] {format % args}\n")
        sys.stdout.flush()

class DualStackServer(ThreadingHTTPServer):
    address_family = socket.AF_INET6

    def server_bind(self):
        try:
            # Enable dual-stack IPv4 + IPv6 so localhost, 127.0.0.1 and [::1] all work
            self.socket.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 0)
        except (AttributeError, OSError):
            pass
        super().server_bind()

def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    serve_dir = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(__file__), "..", "build", "web")
    serve_dir = os.path.abspath(serve_dir)

    os.chdir(serve_dir)

    try:
        httpd = DualStackServer(("", port), GodotWebHandler)
    except Exception:
        # Fallback to standard IPv4 if IPv6 dual-stack is not supported
        httpd = ThreadingHTTPServer(("0.0.0.0", port), GodotWebHandler)

    print("====================================================")
    print(f"  game-x1 Web Server running at: http://localhost:{port}/")
    print(f"  Serving: {serve_dir}")
    print("  Dual-Stack (IPv4 + IPv6) Threading: Active")
    print("====================================================")
    sys.stdout.flush()

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        httpd.server_close()

if __name__ == "__main__":
    main()
