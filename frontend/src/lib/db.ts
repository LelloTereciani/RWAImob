import { Pool } from 'pg';

const pool = new Pool({
    user: process.env.POSTGRES_USER || 'lello',
    host: process.env.DB_HOST || 'localhost',
    database: process.env.POSTGRES_DB || 'rwaimob',
    password: process.env.POSTGRES_PASSWORD || 'password',
    port: parseInt(process.env.DB_PORT || '5432'),
});

export const query = (text: string, params?: any[]) => pool.query(text, params);
