package main

import (
	"errors"

	"github.com/roblaszczak/icedrill"
)

type AccountUUID string

type AccountCreated struct {
	UUID AccountUUID
}

type Withdrawed struct {
	Amount int
}

type Deposited struct {
	Amount int
}

// todo - just idea
//go:generate watermill-es generate -aggregate=Account -idGetter=UUID

type Account struct {
	es icedrill.EventSourced // todo - how to make it private?

	uuid    AccountUUID
	balance int
}

func CreateNewAccount(uuid AccountUUID) *Account {
	a := &Account{}
	a.update(AccountCreated{uuid})

	return a
}

func (a Account) UUID() AccountUUID {
	return a.uuid
}

func (a *Account) Balance() int {
	return a.balance
}

func (a *Account) Withdraw(amount int) error {
	if a.balance < amount {
		return errors.New("not enough money")
	}

	// todo - how to avoid calling handleWithdrawed instead of update?
	a.update(Withdrawed{amount})
	return nil
}

func (a *Account) handleWithdrawed(w Withdrawed) {
	a.balance -= w.Amount
}

func (a *Account) Deposit(amount int) {
	a.update(Deposited{amount})
}

func (a *Account) handleDeposited(d Deposited) {
	a.balance = d.Amount
}

func (a *Account) handleAccountCreated(created AccountCreated) {
	a.uuid = created.UUID
}
