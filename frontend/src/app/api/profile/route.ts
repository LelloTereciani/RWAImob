import { NextResponse } from 'next/server';
import { query } from '@/lib/db';

export async function GET(request: Request) {
    const { searchParams } = new URL(request.url);
    const address = searchParams.get('address');

    if (!address) return NextResponse.json({ error: 'Address required' }, { status: 400 });

    try {
        const res = await query('SELECT * FROM profile WHERE address = $1', [address.toLowerCase()]);
        return NextResponse.json(res.rows[0] || {});
    } catch (err) {
        return NextResponse.json({ error: 'Database error' }, { status: 500 });
    }
}

export async function POST(request: Request) {
    const { address, name, bio, avatarUrl } = await request.json();

    if (!address) return NextResponse.json({ error: 'Address required' }, { status: 400 });

    try {
        const sql = `
      INSERT INTO profile (address, name, bio, avatar_url, updated_at)
      VALUES ($1, $2, $3, $4, $5)
      ON CONFLICT (address) DO UPDATE
      SET name = $2, bio = $3, avatar_url = $4, updated_at = $5
      RETURNING *;
    `;
        const res = await query(sql, [
            address.toLowerCase(),
            name,
            bio,
            avatarUrl,
            Date.now(),
        ]);
        return NextResponse.json(res.rows[0]);
    } catch (err) {
        console.error(err);
        return NextResponse.json({ error: 'Database error' }, { status: 500 });
    }
}
