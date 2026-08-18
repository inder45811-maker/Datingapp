import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

serve(async (req: Request) => {
  try {
    const { imageUrl } = await req.json();
    if (!imageUrl) {
      return new Response(JSON.stringify({ error: "Missing imageUrl" }), { status: 400 });
    }

    const apiUser = Deno.env.get("SIGHTENGINE_API_USER");
    const apiSecret = Deno.env.get("SIGHTENGINE_API_SECRET");

    if (!apiUser || !apiSecret) {
      return new Response(JSON.stringify({ error: "Sightengine credentials unconfigured" }), { status: 500 });
    }

    const endpoint = new URL("https://api.sightengine.com/1.0/check.json");
    endpoint.searchParams.set("url", imageUrl);
    endpoint.searchParams.set("models", "nudity-2.0,offensive,wad");
    endpoint.searchParams.set("api_user", apiUser);
    endpoint.searchParams.set("api_secret", apiSecret);

    const response = await fetch(endpoint.toString());
    const data = await response.json();

    const isSafe =
      data.status === "success" &&
      data.nudity.raw < 0.20 &&
      data.nudity.explicit < 0.05 &&
      data.offensive.prob < 0.15;

    return new Response(JSON.stringify({ isSafe, diagnostics: data }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (err: unknown) {
    const error = err as Error;
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
});
