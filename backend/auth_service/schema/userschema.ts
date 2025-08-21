import z from "zod";

export const user_schema = z.object({
  body: z.object({
    user_email: z.email({ message: "Email is required" }),
  }),
});
