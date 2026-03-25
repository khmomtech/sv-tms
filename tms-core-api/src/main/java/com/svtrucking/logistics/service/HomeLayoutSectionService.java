package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.HomeLayoutSectionDto;
import com.svtrucking.logistics.dto.HomeLayoutSectionRequest;
import com.svtrucking.logistics.entity.HomeLayoutSection;
import com.svtrucking.logistics.repository.HomeLayoutSectionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Service for managing home screen layout sections
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class HomeLayoutSectionService {

    private final HomeLayoutSectionRepository repository;

    /**
     * Get all visible sections for driver app (ordered by displayOrder)
     */
    public List<HomeLayoutSectionDto> getVisibleSections() {
        return repository.findByVisibleTrueOrderByDisplayOrderAsc()
                .stream()
                .map(HomeLayoutSectionDto::toDriverDto)
                .collect(Collectors.toList());
    }

    /**
     * Get all sections for admin (with complete details)
     */
    public List<HomeLayoutSectionDto> getAllSections() {
        return repository.findAllByOrderByDisplayOrderAsc()
                .stream()
                .map(HomeLayoutSectionDto::fromEntity)
                .collect(Collectors.toList());
    }

    /**
     * Get section by ID
     */
    public HomeLayoutSectionDto getSectionById(Long id) {
        HomeLayoutSection section = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Home layout section not found with id: " + id));
        return HomeLayoutSectionDto.fromEntity(section);
    }

    /**
     * Get section by key
     */
    public HomeLayoutSectionDto getSectionByKey(String sectionKey) {
        HomeLayoutSection section = repository.findBySectionKey(sectionKey)
                .orElseThrow(() -> new RuntimeException("Home layout section not found with key: " + sectionKey));
        return HomeLayoutSectionDto.fromEntity(section);
    }

    /**
     * Create new section
     */
    @Transactional
    public HomeLayoutSectionDto createSection(HomeLayoutSectionRequest request, String createdBy) {
        // Check if section key already exists
        if (repository.existsBySectionKey(request.getSectionKey())) {
            throw new RuntimeException("Section with key '" + request.getSectionKey() + "' already exists");
        }

        HomeLayoutSection section = HomeLayoutSection.builder()
                .sectionKey(request.getSectionKey())
                .sectionName(request.getSectionName())
                .sectionNameKh(request.getSectionNameKh())
                .description(request.getDescription())
                .descriptionKh(request.getDescriptionKh())
                .displayOrder(request.getDisplayOrder())
                .visible(request.getVisible())
                .isMandatory(request.getIsMandatory() != null ? request.getIsMandatory() : false)
                .icon(request.getIcon())
                .category(request.getCategory() != null ? request.getCategory() : "general")
                .configJson(request.getConfigJson())
                .createdBy(createdBy)
                .build();

        section = repository.save(section);
        log.info("Created home layout section: {} ({}) by {}", section.getSectionName(), section.getSectionKey(),
                createdBy);
        return HomeLayoutSectionDto.fromEntity(section);
    }

    /**
     * Update existing section
     */
    @Transactional
    public HomeLayoutSectionDto updateSection(Long id, HomeLayoutSectionRequest request, String updatedBy) {
        HomeLayoutSection section = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Home layout section not found with id: " + id));

        // Check if trying to update section key to one that already exists
        if (!section.getSectionKey().equals(request.getSectionKey()) &&
                repository.existsBySectionKey(request.getSectionKey())) {
            throw new RuntimeException("Section with key '" + request.getSectionKey() + "' already exists");
        }

        section.setSectionKey(request.getSectionKey());
        section.setSectionName(request.getSectionName());
        section.setSectionNameKh(request.getSectionNameKh());
        section.setDescription(request.getDescription());
        section.setDescriptionKh(request.getDescriptionKh());
        section.setDisplayOrder(request.getDisplayOrder());
        section.setVisible(request.getVisible());
        section.setIsMandatory(request.getIsMandatory() != null ? request.getIsMandatory() : false);
        section.setIcon(request.getIcon());
        section.setCategory(request.getCategory());
        section.setConfigJson(request.getConfigJson());
        section.setUpdatedBy(updatedBy);

        section = repository.save(section);
        log.info("Updated home layout section: {} ({}) by {}", section.getSectionName(), section.getSectionKey(),
                updatedBy);
        return HomeLayoutSectionDto.fromEntity(section);
    }

    /**
     * Delete section
     */
    @Transactional
    public void deleteSection(Long id) {
        HomeLayoutSection section = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Home layout section not found with id: " + id));

        if (section.getIsMandatory()) {
            throw new RuntimeException("Cannot delete mandatory section: " + section.getSectionKey());
        }

        repository.delete(section);
        log.info("Deleted home layout section: {} ({})", section.getSectionName(), section.getSectionKey());
    }

    /**
     * Toggle section visibility
     */
    @Transactional
    public HomeLayoutSectionDto toggleVisibility(Long id, String updatedBy) {
        HomeLayoutSection section = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Home layout section not found with id: " + id));

        if (section.getIsMandatory() && section.getVisible()) {
            throw new RuntimeException("Cannot hide mandatory section: " + section.getSectionKey());
        }

        section.setVisible(!section.getVisible());
        section.setUpdatedBy(updatedBy);
        section = repository.save(section);

        log.info("{} home layout section: {} ({}) by {}",
                section.getVisible() ? "Showed" : "Hid",
                section.getSectionName(),
                section.getSectionKey(),
                updatedBy);

        return HomeLayoutSectionDto.fromEntity(section);
    }

    /**
     * Reorder sections in batch
     */
    @Transactional
    public List<HomeLayoutSectionDto> reorderSections(List<Long> orderedIds, String updatedBy) {
        for (int i = 0; i < orderedIds.size(); i++) {
            Long id = orderedIds.get(i);
            HomeLayoutSection section = repository.findById(id)
                    .orElseThrow(() -> new RuntimeException("Home layout section not found with id: " + id));

            section.setDisplayOrder(i);
            section.setUpdatedBy(updatedBy);
            repository.save(section);
        }

        log.info("Reordered {} home layout sections by {}", orderedIds.size(), updatedBy);
        return getAllSections();
    }

    /**
     * Initialize default sections if none exist
     */
    @Transactional
    public void initializeDefaultSections() {
        if (repository.count() > 0) {
            log.info("Home layout sections already initialized, skipping...");
            return;
        }

        log.info("Initializing default home layout sections...");

        List<HomeLayoutSection> defaultSections = List.of(
                HomeLayoutSection.builder()
                        .sectionKey("header")
                        .sectionName("Header")
                        .sectionNameKh("ក្បាល")
                        .description("User greeting and notifications")
                        .descriptionKh("ស្វាគមន៍អ្នកប្រើប្រាស់និងការជូនដំណឹង")
                        .displayOrder(0)
                        .visible(true)
                        .isMandatory(true)
                        .icon("person")
                        .category("system")
                        .build(),

                HomeLayoutSection.builder()
                        .sectionKey("maintenance_banner")
                        .sectionName("Maintenance Banner")
                        .sectionNameKh("ផ្ទាំងថែទាំ")
                        .description("System announcements and maintenance alerts")
                        .descriptionKh("ការប្រកាសប្រព័ន្ធនិងការជូនដំណឹងថែទាំ")
                        .displayOrder(1)
                        .visible(true)
                        .isMandatory(false)
                        .icon("warning")
                        .category("system")
                        .build(),

                HomeLayoutSection.builder()
                        .sectionKey("shift_status")
                        .sectionName("Shift Status")
                        .sectionNameKh("ស្ថានភាពវេនការងារ")
                        .description("Current shift information")
                        .descriptionKh("ព័ត៌មានវេនការងារបច្ចុប្បន្ន")
                        .displayOrder(2)
                        .visible(true)
                        .isMandatory(false)
                        .icon("access_time")
                        .category("status")
                        .build(),

                HomeLayoutSection.builder()
                        .sectionKey("safety_status")
                        .sectionName("Safety Status")
                        .sectionNameKh("ស្ថានភាពសុវត្ថិភាព")
                        .description("Pre-trip safety check status")
                        .descriptionKh("ស្ថានភាពពិនិត្យសុវត្ថិភាពមុនដំណើរ")
                        .displayOrder(3)
                        .visible(true)
                        .isMandatory(false)
                        .icon("verified_user")
                        .category("safety")
                        .build(),

                HomeLayoutSection.builder()
                        .sectionKey("important_updates")
                        .sectionName("Important Updates")
                        .sectionNameKh("ព័ត៌មានថ្មីសំខាន់")
                        .description("Banners and announcements from admin")
                        .descriptionKh("ផ្ទាំងនិងការប្រកាសពីអ្នកគ្រប់គ្រង")
                        .displayOrder(4)
                        .visible(true)
                        .isMandatory(false)
                        .icon("campaign")
                        .category("content")
                        .build(),

                HomeLayoutSection.builder()
                        .sectionKey("current_trip")
                        .sectionName("Current Trip")
                        .sectionNameKh("ដំណើរបច្ចុប្បន្ន")
                        .description("Active trip information and progress")
                        .descriptionKh("ព័ត៌មានដំណើរសកម្មនិងដំណើរការ")
                        .displayOrder(5)
                        .visible(true)
                        .isMandatory(false)
                        .icon("local_shipping")
                        .category("trips")
                        .build(),

                HomeLayoutSection.builder()
                        .sectionKey("quick_actions")
                        .sectionName("Quick Actions")
                        .sectionNameKh("សកម្មភាពរហ័ស")
                        .description("Frequently used app features")
                        .descriptionKh("មុខងារកម្មវិធីដែលប្រើញឹកញាប់")
                        .displayOrder(6)
                        .visible(true)
                        .isMandatory(false)
                        .icon("grid_view")
                        .category("navigation")
                        .build());

        repository.saveAll(defaultSections);
        log.info("Initialized {} default home layout sections", defaultSections.size());
    }
}
