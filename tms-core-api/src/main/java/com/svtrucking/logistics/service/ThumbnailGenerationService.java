package com.svtrucking.logistics.service;

import com.svtrucking.logistics.model.DocumentAudit;
import com.svtrucking.logistics.repository.DocumentAuditRepository;
import com.svtrucking.logistics.core.FileStorageProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.rendering.PDFRenderer;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Set;

/**
 * Background worker that generates thumbnails for image/PDF documents to speed up UI previews.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class ThumbnailGenerationService {

    private final DocumentAuditRepository auditRepository;
    private final FileStorageProperties fileStorageProperties;

    private static final Set<String> IMAGE_MIME_PREFIXES = Set.of("image/png", "image/jpeg", "image/jpg", "image/gif", "image/webp");
    private static final String PDF_MIME = "application/pdf";
    // Use configurable width from properties
    private int maxWidth() { return fileStorageProperties.getThumbnailMaxWidth(); }

    @Scheduled(fixedDelayString = "PT10M") // every 10 minutes
    @Transactional
    public void generateMissingThumbnails() {
        var candidates = auditRepository.findByThumbnailUrlIsNullAndThumbnailAttemptedFalse();
        if (candidates.isEmpty()) return;
        log.info("Thumbnail generation starting for {} documents", candidates.size());
        for (DocumentAudit audit : candidates) {
            try {
                attemptThumbnail(audit);
            } catch (Exception e) {
                log.warn("Thumbnail generation failed for document {}: {}", audit.getDocument().getId(), e.getMessage());
            } finally {
                audit.setThumbnailAttempted(true);
                auditRepository.save(audit);
            }
        }
    }

    private void attemptThumbnail(DocumentAudit audit) throws IOException {
        var doc = audit.getDocument();
        String fileUrl = doc.getFileUrl();
        if (fileUrl == null) return;
        Path sourcePath = resolveStoredPath(fileUrl);
        if (!Files.exists(sourcePath)) {
            log.info("Source file missing for thumbnail generation document {}", doc.getId());
            return;
        }
        String mime = audit.getMimeType();
        BufferedImage thumbImage = null;
        if (mime != null && IMAGE_MIME_PREFIXES.contains(mime.toLowerCase())) {
            thumbImage = readAndScaleImage(sourcePath);
        } else if (PDF_MIME.equalsIgnoreCase(mime)) {
            thumbImage = renderPdfFirstPage(sourcePath);
        }
        if (thumbImage == null) return; // unsupported type

        Path thumbDir = fileStorageProperties.documentsPath().resolve("thumbnails");
        Files.createDirectories(thumbDir);
        String filename = doc.getId() + ".jpg"; // store as JPEG
        Path thumbPath = thumbDir.resolve(filename);
        ImageIO.write(thumbImage, "jpg", thumbPath.toFile());
        String publicUrl = fileStorageProperties.publicUrl("documents/thumbnails", filename);
        audit.setThumbnailPath(thumbPath.toString());
        audit.setThumbnailUrl(publicUrl);
        log.info("Generated thumbnail for document {} at {}", doc.getId(), publicUrl);
    }

    private BufferedImage readAndScaleImage(Path src) throws IOException {
        BufferedImage original = ImageIO.read(src.toFile());
    if (original == null) return null;
    int width = original.getWidth();
        int height = original.getHeight();
    int target = maxWidth();
    if (width <= target) return original; // no scale needed
    double scale = (double) target / (double) width;
    int scaledW = target;
        int scaledH = (int) Math.round(height * scale);
        BufferedImage scaled = new BufferedImage(scaledW, scaledH, BufferedImage.TYPE_INT_RGB);
        Graphics2D g2d = scaled.createGraphics();
        g2d.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BILINEAR);
        g2d.drawImage(original, 0, 0, scaledW, scaledH, null);
        g2d.dispose();
        return scaled;
    }

    private BufferedImage renderPdfFirstPage(Path pdfPath) throws IOException {
        try (PDDocument document = PDDocument.load(pdfPath.toFile())) {
            if (document.getNumberOfPages() == 0) return null;
            PDFRenderer renderer = new PDFRenderer(document);
            BufferedImage pageImage = renderer.renderImageWithDPI(0, 72); // 72 DPI baseline
            // scale if wider than max width
            int target = maxWidth();
            if (pageImage.getWidth() > target) {
                double scale = (double) target / (double) pageImage.getWidth();
                int scaledW = target;
                int scaledH = (int) Math.round(pageImage.getHeight() * scale);
                BufferedImage scaled = new BufferedImage(scaledW, scaledH, BufferedImage.TYPE_INT_RGB);
                Graphics2D g2d = scaled.createGraphics();
                g2d.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BILINEAR);
                g2d.drawImage(pageImage, 0, 0, scaledW, scaledH, null);
                g2d.dispose();
                return scaled;
            }
            return pageImage;
        }
    }

    private Path resolveStoredPath(String fileUrl) {
        String working = fileUrl.trim();
        if (working.startsWith("uploads/")) working = "/" + working;
        if (working.startsWith("/uploads/")) {
            String relative = working.substring("/uploads/".length());
            return fileStorageProperties.getBasePath().resolve(relative).normalize();
        }
        return Path.of(working).normalize();
    }
}
