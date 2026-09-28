export function enforceTwoImageVisualRequest({ role, reference, render, comparisonPath, findings }) {
  if (!['E3', 'E4'].includes(role)) throw new Error('visual_role_denied');
  for (const item of [reference, render]) {
    if (!item?.artifact_id || !/^[0-9a-f]{64}$/.test(item.sha256 || '') || !['image/png', 'image/jpeg', 'image/webp'].includes(item.mime_type)) throw new Error('visual_image_missing_or_invalid');
  }
  if (reference.artifact_id === render.artifact_id || reference.sha256 === render.sha256) throw new Error('visual_images_not_distinct');
  if (comparisonPath !== 'genuine_multimodal_same_request') throw new Error('visual_same_request_not_proven');
  if (findings && !Array.isArray(findings)) throw new Error('visual_findings_invalid');
  return true;
}
