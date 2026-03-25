package com.svtrucking.logistics.service;

import com.svtrucking.logistics.model.Shipment;
import com.svtrucking.logistics.repository.ShipmentRepository;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class ShipmentService {
  @Autowired private ShipmentRepository shipmentRepository;

  public List<Shipment> getAllShipments() {
    return shipmentRepository.findAll();
  }

  public Shipment createShipment(Shipment shipment) {
    return shipmentRepository.save(shipment);
  }
}
