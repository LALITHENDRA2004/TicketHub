import axios from 'axios'

export const API_URL = import.meta.env.VITE_API_URL ?? 'http://localhost:8080'

/** Shared Axios instance. Sprint 1 adds the Bearer token and refresh-on-401 interceptors here. */
export const api = axios.create({
  baseURL: API_URL,
  withCredentials: true,
  timeout: 10_000,
})
