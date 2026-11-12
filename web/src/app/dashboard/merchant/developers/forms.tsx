"use client";

import { useActionState } from "react";
import {
  createApiKeyAction,
  rotateSecretAction,
  saveWebhookAction,
  type ApiKeyState,
  type RotateSecretState,
  type WebhookState,
} from "../actions";

const alertClass = "rounded-xl bg-[#FFF5F5] px-3 py-2 text-sm text-kinko";

/** A secret Kinko shows only once: copy it now. */
function SecretOnce({ title, secret }: { title: string; secret: string }) {
  return (
    <div role="status" className="rounded-xl border border-amber-300 bg-amber-50 p-3 text-sm">
      <p className="font-semibold">{title} Copy it now: it won&apos;t be shown again.</p>
      <p className="mt-2 select-all break-all rounded-lg bg-white px-2 py-1 font-mono text-xs">{secret}</p>
    </div>
  );
}

export function NewApiKeyForm() {
  const [state, formAction, pending] = useActionState(createApiKeyAction, { status: "idle" } as ApiKeyState);
  return (
    <div className="space-y-3">
      {state.status === "created" && (
        <div role="status" className="rounded-xl border border-amber-300 bg-amber-50 p-3 text-sm">
          <p className="font-semibold">Key “{state.name}” created. Copy it now: it won&apos;t be shown again.</p>
          <p className="mt-2 select-all break-all rounded-lg bg-white px-2 py-1 font-mono text-xs">{state.secret}</p>
        </div>
      )}
      <form action={formAction} className="flex gap-2">
        <label htmlFor="key-name" className="sr-only">
          Key name
        </label>
        <input id="key-name" name="name" required maxLength={60} placeholder="Key name (e.g. Production)" className="field" />
        <button type="submit" disabled={pending} className="btn-kinko shrink-0">
          {pending ? "Creating…" : "Create key"}
        </button>
      </form>
      {state.status === "error" && (
        <p role="alert" className={alertClass}>
          {state.error}
        </p>
      )}
    </div>
  );
}

export function WebhookUrlForm({ current }: { current?: string }) {
  const [state, formAction, pending] = useActionState(saveWebhookAction, { status: "idle" } as WebhookState);
  return (
    <form action={formAction} className="space-y-2">
      <label htmlFor="webhook-url" className="field-label">
        Endpoint URL
      </label>
      <div className="flex gap-2">
        <input
          id="webhook-url"
          name="url"
          type="url"
          required
          defaultValue={state.status === "error" ? state.url : current}
          placeholder="https://example.com/kinko/webhooks"
          className="field font-mono text-sm"
        />
        <button type="submit" disabled={pending} className="btn-kinko shrink-0">
          {pending ? "Saving…" : "Save"}
        </button>
      </div>
      {state.status === "error" && (
        <p role="alert" className={alertClass}>
          {state.error}
        </p>
      )}
      {state.status === "saved" &&
        (state.secret ? (
          <SecretOnce title="Webhook saved. This is its signing secret." secret={state.secret} />
        ) : (
          <p className="text-sm text-credit">Saved.</p>
        ))}
    </form>
  );
}

export function RotateSecretForm() {
  const [state, formAction, pending] = useActionState(rotateSecretAction, { status: "idle" } as RotateSecretState);
  return (
    <div className="space-y-2">
      {state.status === "rotated" && <SecretOnce title="New signing secret." secret={state.secret} />}
      <form action={formAction}>
        <button type="submit" disabled={pending} className="btn-outline text-xs">
          {pending ? "Rotating…" : "Rotate secret"}
        </button>
      </form>
      {state.status === "error" && (
        <p role="alert" className={alertClass}>
          {state.error}
        </p>
      )}
    </div>
  );
}
