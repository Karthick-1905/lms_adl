import {Request, Response} from 'express'
import db from '../db'

export function register(req:Request, res:Response) {
   const {user_email, user} = req.body
  await db.insert(user)
}

export function login() {}

export function logout() {}
