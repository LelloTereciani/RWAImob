'use client';

import { useQuery } from '@tanstack/react-query';
import { request, gql } from 'graphql-request';

const PONDER_URL = process.env.NEXT_PUBLIC_PONDER_URL || 'http://localhost:42069';

const GET_PROPERTIES = gql`
      query GetProperties {
        propertys {
          items {
            id
            owner
            price
            forSale
            location
            locationHash
            listedAt
          }
        }
      }
    `;

export function useProperties() {
  return useQuery({
    queryKey: ['properties'],
    queryFn: async () => {
      try {
        const data: any = await request(PONDER_URL, GET_PROPERTIES);
        return data.propertys.items;
      } catch (err) {
        console.error("Ponder request failed:", err);
        throw err;
      }
    },
  });
}
