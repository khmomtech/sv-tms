package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.model.Shipment;
import com.svtrucking.logistics.service.ShipmentService;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
public class ShipmentController {

  @Autowired private ShipmentService shipmentService;

  @GetMapping
  public List<Shipment> getAllShipments() {
    return shipmentService.getAllShipments();
  }

  @PostMapping("/create")
  public ResponseEntity<Shipment> createShipment(@RequestBody Shipment shipment) {
    return ResponseEntity.ok(shipmentService.createShipment(shipment));
  }
}
