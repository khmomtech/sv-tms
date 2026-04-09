package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.Item;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

@Repository
public interface ItemRepository extends JpaRepository<Item, Long>, JpaSpecificationExecutor<Item> {

  @Query("select i.itemCode from Item i where i.itemCode is not null")
  Set<String> findAllItemCodes();

  List<Item>
      findByItemNameContainingIgnoreCaseOrSizeContainingIgnoreCaseOrPalletTypeContainingIgnoreCaseOrUnitContainingIgnoreCaseOrWeightContainingIgnoreCase(
          String itemName, String size, String palletType, String unit, String weight);

  List<Item>
      findByItemCodeContainingIgnoreCaseOrItemNameContainingIgnoreCaseOrItemNameKhContainingIgnoreCase(
          String itemCode, String itemName, String itemNameKh);

  List<Item> findByStatus(Integer status);

  Optional<Item> findByItemCode(String itemCode);
}
