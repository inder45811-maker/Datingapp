import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { getAdminClient } from "../_shared/supabase_client.ts";

serve(async (req: Request) => {
  try {
    const authHeader = req.headers.get("Authorization");
    if (authHeader !== `Bearer ${Deno.env.get("RC_WEBHOOK_SECRET")}`) {
      return new Response("Unauthorized", { status: 401 });
    }

    const payload = await req.json();
    const event = payload.event;
    const appUserId = event.app_user_id;
    const type = event.type;

    const supabase = getAdminClient();
    const isPremium = ["INITIAL_PURCHASE", "RENEWAL", "PRODUCT_CHANGE"].includes(type);
    const expirationTime = event.expiration_at_ms
      ? new Date(event.expiration_at_ms).toISOString()
      : null;

    // Handle cancellation / expiration events
    const shouldDeactivate = ["CANCELLATION", "EXPIRATION", "BILLING_ISSUE"].includes(type);

    await supabase
      .from("profiles")
      .update({
        is_premium: shouldDeactivate ? false : isPremium,
        premium_expires_at: shouldDeactivate ? null : expirationTime,
      })
      .eq("id", appUserId);

    return new Response(JSON.stringify({ status: "processed" }), { status: 200 });
  } catch (err: unknown) {
    const error = err as Error;
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
});
