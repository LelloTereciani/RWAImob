import { Hono } from "hono";
import { graphql } from "ponder";
import { db } from "ponder:api";
import schema from "ponder:schema";

import { cors } from "hono/cors";

const app = new Hono();

app.use("/*", cors());

app.use("/graphql", graphql({ db, schema }));
app.use("/", graphql({ db, schema }));

export default app;
