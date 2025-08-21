import express, { Request, Response, Express } from "express";
import cors, { CorsOptions } from "cors";
import dotenv from "dotenv";

dotenv.config();
const PORT = process.env.PORT || 3000;
const app: Express = express();

const corsOptions: CorsOptions = {
  origin: ["*"],
  methods: ["GET", "POST", "PUT", "DELETE", "PATCH"],
  credentials: true,
};

app.use(cors(corsOptions));

app.listen(PORT, () => {
  console.log("Server is running on port 7000");
});
