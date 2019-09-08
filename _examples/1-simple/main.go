package main

import (
	"fmt"

	"github.com/ThreeDotsLabs/watermill"
)

func main() {
	repo := NewRepository()

	a1 := CreateNewAccount(AccountUUID(watermill.NewULID()))
	if err := a1.Deposit(10); err != nil {
		panic(err)
	}
	if err := a1.Withdraw(3); err != nil {
		panic(err)
	}

	fmt.Println("10-3 = ", a1.Balance())

	if err := repo.Save(a1); err != nil {
		panic(err)
	}

	a1Repo, err := repo.Find(a1.UUID())
	if err != nil {
		panic(err)
	}

	fmt.Println("10-3 = (repo)", a1Repo.Balance())
	//
	//a2, err := NewAccountFromHistory([]icedrill.Event{
	//	AccountCreated{"2"},
	//	Deposited{15},
	//	Withdrawed{3},
	//})
	//if err != nil {
	//	panic(err)
	//}
	//fmt.Println("15-3 = ", a2.Balance())
}
