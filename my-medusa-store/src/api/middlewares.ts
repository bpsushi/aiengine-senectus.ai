import { defineMiddlewares, authenticate } from "@medusajs/framework/http"

export default defineMiddlewares({
  routes: [
    {
      matcher: "/mcp*",
      middlewares: [],
      bodyParser: { preserveRawBody: true },
    },
  ],
})
