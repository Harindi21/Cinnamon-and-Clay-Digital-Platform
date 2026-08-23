'use client';

import { useEffect } from 'react';

type ErrorPageProps = {
  error: Error & {
    digest?: string;
  };
  reset: () => void;
};

export default function ErrorPage({
  error,
  reset
}: ErrorPageProps) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <main className="pageState">
      <div className="pageStateCard">
        <p className="sectionKicker">Something went wrong</p>

        <h1>We could not load the cafe right now.</h1>

        <p>
          Please try again in a moment.
        </p>

        <button type="button" onClick={reset}>
          Try again
        </button>
      </div>
    </main>
  );
}