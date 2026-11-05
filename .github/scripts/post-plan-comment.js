/**
 * Post or update a PR comment summarizing a Terraform plan.
 * Intended for actions/github-script: require this module and call with { github, context }.
 *
 * Env: PLAN_EXIT, STACK, TF_ENV, SCHEME, RUN_URL, ARTIFACT_NAME
 * Optional: GITHUB_WORKSPACE (default cwd root for plan.txt path)
 */
'use strict';

const fs = require('fs');
const path = require('path');

const PREVIEW_MAX = 8000;

function buildCommentBody(plan, env) {
  const exit = env.PLAN_EXIT || '1';
  const status =
    exit === '0' ? 'No changes' :
    exit === '2' ? 'Changes present' :
    `Failed (exit ${exit})`;

  const summaryMatch = plan.match(
    /Plan:\s+(\d+)\s+to add,\s+(\d+)\s+to change,\s+(\d+)\s+to destroy/
  );
  const planSummary = summaryMatch
    ? `Plan: **${summaryMatch[1]}** to add, **${summaryMatch[2]}** to change, **${summaryMatch[3]}** to destroy`
    : (exit === '0'
      ? 'Plan: **0** to add, **0** to change, **0** to destroy'
      : '_No Plan: summary found_');

  const resourceLines = plan
    .split('\n')
    .filter((line) => /^\s*#\s+.+\s+will be\b|^\s*#\s+.+\s+must be replaced\b/i.test(line))
    .map((line) => line.trim())
    .slice(0, 40);
  const resourceBlock = resourceLines.length
    ? ['', '**Resources:**', ...resourceLines.map((l) => `- \`${l.replace(/^#\s*/, '')}\``)].join('\n')
    : '';

  let preview = plan.trimEnd();
  let truncated = false;
  if (preview.length > PREVIEW_MAX) {
    preview = preview.slice(0, PREVIEW_MAX).trimEnd();
    truncated = true;
  }
  if (truncated) {
    preview += '\n\n… truncated — download the artifact for the full plan.txt …';
  }

  const marker = `<!-- terraform-plan:${env.STACK}:${env.TF_ENV} -->`;
  const body = [
    marker,
    `### Terraform plan \`${env.STACK}\` (\`${env.TF_ENV}\`)`,
    '',
    `- Scheme: **${env.SCHEME}**`,
    `- Result: **${status}**`,
    `- ${planSummary}`,
    `- Full plan: [\`${env.ARTIFACT_NAME}\`](${env.RUN_URL}) (Artifacts on the workflow run)`,
    resourceBlock,
    '',
    `<details><summary>Plan preview${truncated ? ' (truncated)' : ''}</summary>`,
    '',
    '```diff',
    preview,
    '```',
    '',
    '</details>',
  ].join('\n');

  return { marker, body };
}

async function postPlanComment({ github, context }) {
  const root = process.env.GITHUB_WORKSPACE || process.cwd();
  const planPath = path.join(root, 'stacks', process.env.STACK, 'plan.txt');
  const plan = fs.existsSync(planPath)
    ? fs.readFileSync(planPath, 'utf8')
    : '(no plan output)';

  const { marker, body } = buildCommentBody(plan, process.env);

  const { data: comments } = await github.rest.issues.listComments({
    owner: context.repo.owner,
    repo: context.repo.repo,
    issue_number: context.issue.number,
  });
  const existing = comments.find((c) => c.body && c.body.includes(marker));
  if (existing) {
    await github.rest.issues.updateComment({
      owner: context.repo.owner,
      repo: context.repo.repo,
      comment_id: existing.id,
      body,
    });
  } else {
    await github.rest.issues.createComment({
      owner: context.repo.owner,
      repo: context.repo.repo,
      issue_number: context.issue.number,
      body,
    });
  }
}

module.exports = postPlanComment;
module.exports.buildCommentBody = buildCommentBody;
