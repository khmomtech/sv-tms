package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.StaffMemberDto;
import com.svtrucking.logistics.exception.ResourceNotFoundException;
import com.svtrucking.logistics.model.StaffMember;
import com.svtrucking.logistics.repository.StaffMemberRepository;
import com.svtrucking.logistics.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class StaffMemberService {

  private final StaffMemberRepository staffRepository;
  private final UserRepository userRepository;

  @Transactional(readOnly = true)
  public Page<StaffMemberDto> list(String search, Boolean active, Pageable pageable) {
    String q = (search == null || search.isBlank()) ? null : search.trim();
    return staffRepository.search(q, active, pageable).map(StaffMemberDto::fromEntity);
  }

  @Transactional(readOnly = true)
  public StaffMemberDto get(Long id) {
    StaffMember staff =
        staffRepository.findById(id).orElseThrow(() -> new ResourceNotFoundException("Staff not found: " + id));
    return StaffMemberDto.fromEntity(staff);
  }

  @Transactional
  public StaffMemberDto create(StaffMemberDto dto) {
    StaffMember staff = new StaffMember();
    if (dto.getUserId() != null) {
      staff.setUser(userRepository.findById(dto.getUserId()).orElse(null));
    }
    staff.setFullName(dto.getFullName());
    staff.setEmail(dto.getEmail());
    staff.setPhone(dto.getPhone());
    staff.setJobTitle(dto.getJobTitle());
    staff.setDepartment(dto.getDepartment());
    staff.setActive(dto.getActive() != null ? dto.getActive() : true);
    return StaffMemberDto.fromEntity(staffRepository.save(staff));
  }

  @Transactional
  public StaffMemberDto update(Long id, StaffMemberDto dto) {
    StaffMember staff =
        staffRepository.findById(id).orElseThrow(() -> new ResourceNotFoundException("Staff not found: " + id));
    if (dto.getUserId() != null) {
      staff.setUser(userRepository.findById(dto.getUserId()).orElse(null));
    }
    if (dto.getFullName() != null) staff.setFullName(dto.getFullName());
    staff.setEmail(dto.getEmail());
    staff.setPhone(dto.getPhone());
    staff.setJobTitle(dto.getJobTitle());
    staff.setDepartment(dto.getDepartment());
    if (dto.getActive() != null) staff.setActive(dto.getActive());
    return StaffMemberDto.fromEntity(staffRepository.save(staff));
  }

  @Transactional
  public void deactivate(Long id) {
    StaffMember staff =
        staffRepository.findById(id).orElseThrow(() -> new ResourceNotFoundException("Staff not found: " + id));
    staff.setActive(false);
    staffRepository.save(staff);
  }
}
