# SOP 05 - Handover and Reporting

## Purpose

Make shift handover clear, short, and complete.

## Handover Template

1. System status:
   - auth: healthy/unhealthy
   - driver-app: healthy/unhealthy
   - nginx: healthy/unhealthy

2. Today changes:
   - release ID/time
   - key config changes

3. Validation result:
   - routing smoke: pass/fail
   - OpenAPI smoke: pass/fail
   - mobile smoke: pass/fail

4. Open risks:
   - known issues
   - mitigation

5. Next actions:
   - owner
   - deadline

## Recommended Evidence Attachment

Attach stabilization watch log:

```bash
infra/scripts/post_deploy_smoke.sh \
  --vps root@YOUR_VPS --ssh-key ~/.ssh/id_ed25519 \
  --duration-min 60 --interval-sec 60
```

Use generated report from `deploy/reports/` as handover evidence.

## Reporting Rule

- Report facts only: what happened, what was checked, result.
- Do not close incident without proof (health + smoke + user flow).
