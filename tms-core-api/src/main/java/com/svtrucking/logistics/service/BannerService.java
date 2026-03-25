package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.BannerDto;
import com.svtrucking.logistics.entity.Banner;
import com.svtrucking.logistics.repository.BannerRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Service for managing banners/announcements
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class BannerService {

    private final BannerRepository bannerRepository;

    /**
     * Get all active banners for driver app (within valid date range)
     */
    public List<BannerDto> getActiveBanners() {
        List<Banner> banners = bannerRepository.findActiveBanners(LocalDateTime.now());
        
        // Increment view counts
        banners.forEach(Banner::incrementViewCount);
        bannerRepository.saveAll(banners);
        
        return banners.stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    /**
     * Get active banners by category
     */
    public List<BannerDto> getActiveBannersByCategory(String category) {
        List<Banner> banners = bannerRepository.findActiveBannersByCategory(category, LocalDateTime.now());
        return banners.stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    /**
     * Get all banners (admin view)
     */
    public List<BannerDto> getAllBanners() {
        return bannerRepository.findAllByOrderByDisplayOrderAscCreatedAtDesc().stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    /**
     * Get banner by ID
     */
    public BannerDto getBannerById(Long id) {
        Banner banner = bannerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Banner not found with id: " + id));
        return convertToDto(banner);
    }

    /**
     * Create new banner
     */
    @Transactional
    public BannerDto createBanner(BannerDto dto, String createdBy) {
        Banner banner = Banner.builder()
                .title(dto.getTitle())
                .titleKh(dto.getTitleKh())
                .subtitle(dto.getSubtitle())
                .subtitleKh(dto.getSubtitleKh())
                .imageUrl(dto.getImageUrl())
                .category(dto.getCategory() != null ? dto.getCategory() : "general")
                .targetUrl(dto.getTargetUrl())
                .displayOrder(dto.getDisplayOrder() != null ? dto.getDisplayOrder() : 0)
                .startDate(dto.getStartDate() != null ? dto.getStartDate() : LocalDateTime.now())
                .endDate(dto.getEndDate() != null ? dto.getEndDate() : LocalDateTime.now().plusYears(1))
                .active(dto.getActive() != null ? dto.getActive() : true)
                .createdBy(createdBy)
                .build();

        banner = bannerRepository.save(banner);
        log.info("Created banner: {} by {}", banner.getId(), createdBy);
        return convertToDto(banner);
    }

    /**
     * Update existing banner
     */
    @Transactional
    public BannerDto updateBanner(Long id, BannerDto dto) {
        Banner banner = bannerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Banner not found with id: " + id));

        if (dto.getTitle() != null) banner.setTitle(dto.getTitle());
        if (dto.getTitleKh() != null) banner.setTitleKh(dto.getTitleKh());
        if (dto.getSubtitle() != null) banner.setSubtitle(dto.getSubtitle());
        if (dto.getSubtitleKh() != null) banner.setSubtitleKh(dto.getSubtitleKh());
        if (dto.getImageUrl() != null) banner.setImageUrl(dto.getImageUrl());
        if (dto.getCategory() != null) banner.setCategory(dto.getCategory());
        if (dto.getTargetUrl() != null) banner.setTargetUrl(dto.getTargetUrl());
        if (dto.getDisplayOrder() != null) banner.setDisplayOrder(dto.getDisplayOrder());
        if (dto.getStartDate() != null) banner.setStartDate(dto.getStartDate());
        if (dto.getEndDate() != null) banner.setEndDate(dto.getEndDate());
        if (dto.getActive() != null) banner.setActive(dto.getActive());

        banner = bannerRepository.save(banner);
        log.info("Updated banner: {}", banner.getId());
        return convertToDto(banner);
    }

    /**
     * Delete banner
     */
    @Transactional
    public void deleteBanner(Long id) {
        if (!bannerRepository.existsById(id)) {
            throw new RuntimeException("Banner not found with id: " + id);
        }
        bannerRepository.deleteById(id);
        log.info("Deleted banner: {}", id);
    }

    /**
     * Track banner click
     */
    @Transactional
    public void trackBannerClick(Long id) {
        Banner banner = bannerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Banner not found with id: " + id));
        banner.incrementClickCount();
        bannerRepository.save(banner);
        log.debug("Banner {} clicked, total clicks: {}", id, banner.getClickCount());
    }

    /**
     * Increment click count (silent fail version for public API)
     */
    @Transactional
    public void incrementClickCount(Long id) {
        try {
            bannerRepository.findById(id).ifPresent(banner -> {
                banner.incrementClickCount();
                bannerRepository.save(banner);
            });
        } catch (Exception e) {
            log.warn("Failed to increment click count for banner {}: {}", id, e.getMessage());
        }
    }

    /**
     * Convert entity to DTO
     */
    private BannerDto convertToDto(Banner banner) {
        return BannerDto.builder()
                .id(banner.getId())
                .title(banner.getTitle())
                .titleKh(banner.getTitleKh())
                .subtitle(banner.getSubtitle())
                .subtitleKh(banner.getSubtitleKh())
                .imageUrl(banner.getImageUrl())
                .category(banner.getCategory())
                .targetUrl(banner.getTargetUrl())
                .displayOrder(banner.getDisplayOrder())
                .startDate(banner.getStartDate())
                .endDate(banner.getEndDate())
                .active(banner.getActive())
                .clickCount(banner.getClickCount())
                .viewCount(banner.getViewCount())
                .createdBy(banner.getCreatedBy())
                .createdAt(banner.getCreatedAt())
                .updatedAt(banner.getUpdatedAt())
                .build();
    }
}
