package main

import (
	"encoding/json"
	"fmt"
	"log"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SmartContract struct {
	contractapi.Contract
}

type Product struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Type        string `json:"type"` // "food" or "pharma"
	Origin      string `json:"origin"`
	Manufacturer string `json:"manufacturer"`
	BatchNumber string `json:"batchNumber"`
	ExpiryDate  string `json:"expiryDate"`
	Status      string `json:"status"`
	Owner       string `json:"owner"`
	Timestamp   string `json:"timestamp"`
}

func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	products := []Product{
		{ID: "FOOD001", Name: "Organic Apples", Type: "food", Origin: "Farm A", Manufacturer: "FreshFarms", BatchNumber: "B001", ExpiryDate: "2024-12-31", Status: "fresh", Owner: "FoodOrg", Timestamp: "2024-01-01"},
		{ID: "PHARMA001", Name: "Aspirin", Type: "pharma", Origin: "Lab B", Manufacturer: "PharmaCorp", BatchNumber: "P001", ExpiryDate: "2025-06-30", Status: "active", Owner: "PharmaOrg", Timestamp: "2024-01-01"},
	}

	for _, product := range products {
		productJSON, err := json.Marshal(product)
		if err != nil {
			return err
		}

		err = ctx.GetStub().PutState(product.ID, productJSON)
		if err != nil {
			return fmt.Errorf("failed to put to world state. %v", err)
		}
	}

	return nil
}

func (s *SmartContract) CreateProduct(ctx contractapi.TransactionContextInterface, id string, name string, productType string, origin string, manufacturer string, batchNumber string, expiryDate string, status string, owner string, timestamp string) error {
	exists, err := s.ProductExists(ctx, id)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("the product %s already exists", id)
	}

	product := Product{
		ID:          id,
		Name:        name,
		Type:        productType,
		Origin:      origin,
		Manufacturer: manufacturer,
		BatchNumber: batchNumber,
		ExpiryDate:  expiryDate,
		Status:      status,
		Owner:       owner,
		Timestamp:   timestamp,
	}
	
	productJSON, err := json.Marshal(product)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(id, productJSON)
}

func (s *SmartContract) ReadProduct(ctx contractapi.TransactionContextInterface, id string) (*Product, error) {
	productJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return nil, fmt.Errorf("failed to read from world state: %v", err)
	}
	if productJSON == nil {
		return nil, fmt.Errorf("the product %s does not exist", id)
	}

	var product Product
	err = json.Unmarshal(productJSON, &product)
	if err != nil {
		return nil, err
	}

	return &product, nil
}

func (s *SmartContract) ProductExists(ctx contractapi.TransactionContextInterface, id string) (bool, error) {
	productJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}

	return productJSON != nil, nil
}

func (s *SmartContract) TransferProduct(ctx contractapi.TransactionContextInterface, id string, newOwner string, timestamp string) error {
	product, err := s.ReadProduct(ctx, id)
	if err != nil {
		return err
	}

	product.Owner = newOwner
	product.Timestamp = timestamp
	
	productJSON, err := json.Marshal(product)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(id, productJSON)
}

func (s *SmartContract) GetAllProducts(ctx contractapi.TransactionContextInterface) ([]*Product, error) {
	resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var products []*Product
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var product Product
		err = json.Unmarshal(queryResponse.Value, &product)
		if err != nil {
			return nil, err
		}
		products = append(products, &product)
	}

	return products, nil
}

func main() {
	productChaincode, err := contractapi.NewChaincode(&SmartContract{})
	if err != nil {
		log.Panicf("Error creating foodpharma chaincode: %v", err)
	}

	if err := productChaincode.Start(); err != nil {
		log.Panicf("Error starting foodpharma chaincode: %v", err)
	}
}