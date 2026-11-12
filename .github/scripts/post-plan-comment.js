/**
 * Post or update a PR comment summarizing a Terraform plan.
 * Env: PLAN_EXIT, STACK, TF_ENV, RUN_URL, ARTIFACT_NAME
 */
'use strict';

const fs = require('fs');
const path = require('path');

const PLAN_MAX = 60000;

function fencePlan(plan) {
  const longest = (plan.match(/`+/g) || []).reduce((n, s) => Math.max(n, s.length), 0);
  const ticks = '`'.repeat(Math.max(3, longest + 1));
  return `${ticks}\n${plan}\n${ticks}`;
}

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

  let output = plan.trimEnd();
  let truncated = false;
  if (output.length > PLAN_MAX) {
    output = output.slice(0, PLAN_MAX).trimEnd();
    truncated = true;
  }
  if (truncated) {
    output += '\n\n… truncated — download the artifact for the full plan.txt …';
  }

  const marker = `<!-- terraform-plan:${env.STACK}:${env.TF_ENV} -->`;
  const body = [
    marker,
    `### Terraform plan \`${env.STACK}\` (\`${env.TF_ENV}\`)`,
    '',
    `- Result: **${status}**`,
    `- ${planSummary}`,
    `- Full plan: [\`${env.ARTIFACT_NAME}\`](${env.RUN_URL}) (Artifacts on the workflow run)`,
    '',
    `<details><summary>Plan output${truncated ? ' (truncated)' : ''}</summary>`,
    '',
    fencePlan(output),
    '',
    '</details>',
  ].join('\n');

  return { marker, body };
}

async function findPlanComment(github, context, marker) {
  const iterator = github.paginate.iterator(github.rest.issues.listComments, {
    owner: context.repo.owner,
    repo: context.repo.repo,
    issue_number: context.issue.number,
    per_page: 100,
  });
  for await (const { data: comments } of iterator) {
    const hit = comments.find(
      (c) =>
        c.user &&
        c.user.login === 'github-actions[bot]' &&
        c.body &&
        c.body.includes(marker)
    );
    if (hit) return hit;
  }
  return null;
}

async function postPlanComment({ github, context }) {
  const root = process.env.GITHUB_WORKSPACE || process.cwd();
  const planPath = path.join(root, 'stacks', process.env.STACK, 'plan.txt');
  const plan = fs.existsSync(planPath)
    ? fs.readFileSync(planPath, 'utf8')
    : '(no plan output)';

  const { marker, body } = buildCommentBody(plan, process.env);
  const existing = await findPlanComment(github, context, marker);

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
