import { Router } from "express";

const router = Router();

router.route("/login").post();
router.route("/register").post();
router.route("/logout").post();

export default router;
