import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { getAdminClient } from "../_shared/supabase_client.ts";

interface SwipePayload {
  swiper_id: string;
  swiped_id: string;
  direction: "like" | "dislike" | "superlike";
}

serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  try {
    const { swiper_id, swiped_id, direction }: SwipePayload = await req.json();
    if (!swiper_id || !swiped_id || !direction) {
      return new Response(JSON.stringify({ error: "Missing required fields" }), { status: 400 });
    }

    const supabase = getAdminClient();

    // 1. Record the Swipe in Ledger
    const { error: swipeError } = await supabase
      .from("swipes")
      .upsert({ swiper_id, swiped_id, direction }, { onConflict: "swiper_id,swiped_id" });

    if (swipeError) throw swipeError;

    let isMatch = false;
    let matchPayload = null;

    // 2. Check for Mutual Like
    if (direction === "like" || direction === "superlike") {
      const { data: reciprocalSwipe } = await supabase
        .from("swipes")
        .select("direction")
        .eq("swiper_id", swiped_id)
        .eq("swiped_id", swiper_id)
        .in("direction", ["like", "superlike"])
        .maybeSingle();

      if (reciprocalSwipe) {
        isMatch = true;
        // Deterministic low-to-high UUID mapping
        const [u1, u2] = swiper_id < swiped_id ? [swiper_id, swiped_id] : [swiped_id, swiper_id];

        const { data: match, error: matchError } = await supabase
          .from("matches")
          .upsert({ user1_id: u1, user2_id: u2 }, { onConflict: "user1_id,user2_id" })
          .select()
          .single();

        if (matchError) throw matchError;
        matchPayload = match;

        // Auto-seed conversation with a system match message
        await supabase.from("messages").insert({
          match_id: match.id,
          sender_id: swiper_id,
          content: "⚡ It's a mutual connection! Free messaging is unlocked.",
        });
      }
    }

    return new Response(
      JSON.stringify({ success: true, isMatch, match: matchPayload }),
      { headers: { "Content-Type": "application/json" }, status: 200 }
    );
  } catch (err: unknown) {
    const error = err as Error;
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
});
