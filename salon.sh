#!/bin/bash

# Connessione al database postgres per creare il database salon
psql --username=freecodecamp --dbname=postgres -c "CREATE DATABASE salon;" 2> /dev/null

# Connessione al database salon per creare le tabelle
psql --username=freecodecamp --dbname=salon -c "\
CREATE TABLE IF NOT EXISTS customers (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL
);" 2> /dev/null

psql --username=freecodecamp --dbname=salon -c "\
CREATE TABLE IF NOT EXISTS services (
    service_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);" 2> /dev/null

psql --username=freecodecamp --dbname=salon -c "\
CREATE TABLE IF NOT EXISTS appointments (
    appointment_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    service_id INTEGER REFERENCES services(service_id),
    time VARCHAR(255) NOT NULL
);" 2> /dev/null

# Inserimento dei servizi (solo se la tabella è vuota)
SERVICE_COUNT=$(psql --username=freecodecamp --dbname=salon -t -c "SELECT COUNT(*) FROM services;")
SERVICE_COUNT=$(echo $SERVICE_COUNT | xargs)

if [[ $SERVICE_COUNT -eq 0 ]]
then
  psql --username=freecodecamp --dbname=salon -c "\
  INSERT INTO services (service_id, name) VALUES
  (1, 'Taglio'),
  (2, 'Colorazione'),
  (3, 'Trattamento');" 2> /dev/null
fi

# Funzione per mostrare i servizi
SHOW_SERVICES() {
  echo -e "\nBenvenuto nel salone!"
  echo -e "Ecco i servizi disponibili:"
  # Recupera i servizi dal database e li mostra in formato numerato
  SERVICES=$(psql --username=freecodecamp --dbname=salon -t -c "SELECT service_id, name FROM services ORDER BY service_id;")
  echo "$SERVICES" | while read SERVICE_ID BAR SERVICE_NAME
  do
    echo "$SERVICE_ID) $SERVICE_NAME"
  done
}

# Funzione per leggere la selezione del servizio
READ_SERVICE() {
  while true
  do
    echo -e "\nSeleziona un servizio digitando il numero corrispondente:"
    read SERVICE_ID_SELECTED

    # Verifica se l'input è un numero
    if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
    then
      echo -e "\nInserisci un numero valido."
      SHOW_SERVICES
      continue
    fi

    # Verifica se il service_id esiste
    SERVICE_AVAILABLE=$(psql --username=freecodecamp --dbname=salon -t -c "SELECT service_id FROM services WHERE service_id = $SERVICE_ID_SELECTED;")

    if [[ -z $SERVICE_AVAILABLE ]]
    then
      echo -e "\nServizio non disponibile. Riprova."
      SHOW_SERVICES
    else
      break
    fi
  done
}

# Funzione per leggere il numero di telefono
READ_PHONE() {
  echo -e "\nPer favore, inserisci il tuo numero di telefono (es. 555-555-5555):"
  read CUSTOMER_PHONE
}

# Funzione per leggere il nome del cliente (se necessario)
READ_NAME() {
  echo -e "\nSembra che tu non sia ancora un cliente."
  echo -e "Per favore, inserisci il tuo nome:"
  read CUSTOMER_NAME
}

# Funzione per leggere l'orario dell'appuntamento
READ_TIME() {
  echo -e "\nInserisci l'orario desiderato per l'appuntamento (es. 10:30):"
  read SERVICE_TIME
}

# Funzione per ottenere l'ID del cliente
GET_CUSTOMER_ID() {
  # Recupera l'ID del cliente se esiste
  CUSTOMER_ID=$(psql --username=freecodecamp --dbname=salon -t -c "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE';")
  CUSTOMER_ID=$(echo $CUSTOMER_ID | xargs) # Rimuove gli spazi bianchi
}

# Funzione per aggiungere un nuovo cliente
ADD_CUSTOMER() {
  READ_NAME
  # Inserisce il nuovo cliente nella tabella customers
  INSERT_CUSTOMER_RESULT=$(psql --username=freecodecamp --dbname=salon -c "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE');")
  # Ottiene l'ID del nuovo cliente
  GET_CUSTOMER_ID
}

# Funzione per aggiungere un appuntamento
ADD_APPOINTMENT() {
  # Inserisce l'appuntamento nella tabella appointments
  INSERT_APPOINTMENT_RESULT=$(psql --username=freecodecamp --dbname=salon -c "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME');")
}

# Funzione per mostrare la conferma
SHOW_CONFIRMATION() {
  # Recupera il nome del servizio
  SERVICE_NAME=$(psql --username=freecodecamp --dbname=salon -t -c "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED;")
  SERVICE_NAME=$(echo $SERVICE_NAME | xargs) # Rimuove gli spazi bianchi

  # Recupera il nome del cliente
  CUSTOMER_NAME=$(psql --username=freecodecamp --dbname=salon -t -c "SELECT name FROM customers WHERE customer_id = $CUSTOMER_ID;")
  CUSTOMER_NAME=$(echo $CUSTOMER_NAME | xargs) # Rimuove gli spazi bianchi

  echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
}

# Funzione principale
MAIN() {
  SHOW_SERVICES
  READ_SERVICE
  READ_PHONE
  GET_CUSTOMER_ID

  # Se il cliente non esiste, aggiungilo
  if [[ -z $CUSTOMER_ID ]]
  then
    ADD_CUSTOMER
  fi

  # Leggi l'orario dell'appuntamento
  READ_TIME

  # Aggiungi l'appuntamento
  ADD_APPOINTMENT

  # Mostra la conferma
  SHOW_CONFIRMATION
}

# Esegui la funzione principale
MAIN
