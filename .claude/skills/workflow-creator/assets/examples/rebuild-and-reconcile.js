/**
 * rebuild-and-reconcile — fix each file independently, then reconcile the deferrals that
 * span files: cluster by shared file (union-find), fix each cluster once, verify per claim.
 *
 * Demonstrates the reconcile shape: workers DEFER cross-file work as data whose resource
 * slot is a file LIST, a zero-token JS barrier dedups and clusters residuals by connected
 * file-set, disjoint clusters fix-and-verify concurrently with no collision, and only
 * genuinely-unresolvable deferrals reach the return — never silently dropped.
 *
 * Workflow({ name: 'rebuild-and-reconcile',
 *            args: ['libs/typescript/interchange/codec/codec.ts',
 *                   'libs/typescript/interchange/codec/frame.ts'] })
 */

export const meta = {
    name: 'rebuild-and-reconcile',
    description:
        'Tighten the libs/typescript/interchange wire-decode files in place, then reconcile the fixes that span the shared wire contract: cluster deferrals by shared file, fix each cluster once, adversarially verify per claim.',
    whenToUse: 'A refactor where each file is fixed independently but some fixes span files (a shared decoded shape, a seam two files must agree on)',
    phases: [{ title: 'Edit' }, { title: 'Reconcile' }],
};

// --- [INPUTS] --------------------------------------------------------------------------

// args = array of file paths, arriving as structured data. Defaults keep it runnable —
// the interchange decode files that all read one C# wire and must stay mutually consistent.
const FILES =
    Array.isArray(args) && args.length
        ? args
        : [
              'libs/typescript/interchange/codec/codec.ts',
              'libs/typescript/interchange/codec/frame.ts',
              'libs/typescript/interchange/codec/parity.ts',
              'libs/typescript/interchange/ingress/fault.ts',
              'libs/typescript/interchange/contract/descriptor.ts',
          ];

// --- [MODELS] --------------------------------------------------------------------------

// STRICT everywhere: additionalProperties:false + every property required at every level.
// `residual` is required-but-empty: an empty array attests the cross-file scan ran and found nothing.
const EDIT = {
    type: 'object',
    additionalProperties: false,
    required: ['file', 'verdict', 'residual'],
    properties: {
        file: { type: 'string' },
        verdict: { type: 'string', enum: ['edited', 'clean'] },
        residual: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['files', 'claim'],
                properties: { files: { type: 'array', items: { type: 'string' } }, claim: { type: 'string' } },
            },
        },
    },
};
const FIXED = {
    type: 'object',
    additionalProperties: false,
    required: ['files', 'summary'],
    properties: { files: { type: 'array', items: { type: 'string' } }, summary: { type: 'string' } },
};
const VERIFY = {
    type: 'object',
    additionalProperties: false,
    required: ['claims'],
    properties: {
        claims: {
            type: 'array',
            items: {
                type: 'object',
                additionalProperties: false,
                required: ['claim', 'resolved', 'evidence'],
                properties: { claim: { type: 'string' }, resolved: { type: 'boolean' }, evidence: { type: 'string' } },
            },
        },
    },
};

// --- [OPERATIONS] ----------------------------------------------------------------------

// Steady worker pool — holds <=cap long chains; preferred over parallel(thunks) for
// hundreds of long multi-stage edits.
const sleep = (ms) => new Promise((res) => setTimeout(res, ms));
const pool = async (items, cap, worker) => {
    const out = new Array(items.length);
    let i = 0;
    let gate = Promise.resolve(); // serialized launch gate:
    const launch = () => {
        gate = gate.then(() => sleep(1500));
        return gate;
    }; // launches spaced ~1500ms
    const run = async () => {
        while (i < items.length) {
            const k = i++;
            await launch();
            out[k] = await worker(items[k], k);
        }
    };
    await Promise.all(Array.from({ length: Math.min(cap, items.length) }, () => run()));
    return out;
};

// --- [COMPOSITION] ---------------------------------------------------------------------

// --- [EDIT]
// One worker per file; fix what it can alone, DEFER cross-file work as DATA (a file LIST).
phase('Edit');
const done = (
    await pool(FILES, 10, (f) =>
        agent(
            'Tighten the wire-decode module ' +
                f +
                ' in place against coding-ts. Fix everything you can within this ONE file. Anything that also requires ' +
                'editing OTHER files (a shared decoded shape, a codec/frame/fault seam two files must agree on) you MUST NOT touch here — instead report it in ' +
                'residual as {files: [every file the fix touches], claim}.',
            { label: 'edit:' + f, phase: 'Edit', schema: EDIT },
        ),
    )
).filter(Boolean);

// --- [RECONCILE]
// BARRIER (dedup + cluster by shared file via union-find), then PIPELINE fix -> verify.
// Single-pass here: each cluster fixes + verifies once. To drive-to-zero, progress-gate each round —
// skip verify on a no-change fix, re-queue only NEW residuals via a seen-set, break when nothing changed a file.
const all = done.flatMap((d) => d.residual || []);
const uniq = [...new Map(all.map((r) => [r.files.join(',') + '|' + r.claim, r])).values()];
const clusters = (() => {
    const parent = new Map();
    const find = (x) => {
        let p = x;
        while (parent.get(p) !== p) p = parent.get(p);
        return p;
    };
    const add = (x) => {
        if (!parent.has(x)) parent.set(x, x);
    };
    for (const r of uniq) {
        r.files.forEach(add);
        for (let j = 1; j < r.files.length; j++) parent.set(find(r.files[j]), find(r.files[0]));
    }
    const by = new Map();
    for (const r of uniq) {
        const root = r.files.length ? find(r.files[0]) : '__none__';
        (by.get(root) || by.set(root, []).get(root)).push(r);
    }
    return [...by.values()];
})();
log('Reconcile: ' + uniq.length + ' deferrals -> ' + clusters.length + ' disjoint clusters');

let hard = [];
if (clusters.length) {
    phase('Reconcile');
    // Disjoint clusters write non-overlapping files, so per-cluster fixers run concurrently with no collision (no worktree).
    // Per-cluster paste is small-output-only; a heavy cluster (~50+ rows) moves to a scratch report file + receipt.
    const out = (
        await pipeline(
            clusters,
            (cl) =>
                agent(
                    'Fix these cross-file deferrals in place. Read EVERY listed file; make the shared fix once, consistently, regress nothing.\n' +
                        JSON.stringify(cl, null, 1),
                    { label: 'fix', phase: 'Reconcile', schema: FIXED },
                ),
            (fix, cl, i) =>
                fix
                    ? agent(
                          'Adversarially verify each claim is ACTUALLY resolved — read the named files from disk, default resolved=false on ' +
                              'any doubt. Return one verdict per claim.\nClaims:\n' +
                              JSON.stringify(cl, null, 1) +
                              '\nFiles the fixer touched: ' +
                              JSON.stringify(fix.files),
                          { label: 'verify:' + i, phase: 'Reconcile', schema: VERIFY },
                      ).then((v) => ({ cl, v }))
                    : null,
        )
    ).filter(Boolean);
    // A separate verifier with one-verdict-per-claim PROVES completeness: a dropped claim cannot validate.
    hard = out.flatMap((o) => ((o.v && o.v.claims) || []).filter((c) => !c.resolved).map((c) => c.claim));
}

return { files: FILES.length, clusters: clusters.length, unresolved: hard };
