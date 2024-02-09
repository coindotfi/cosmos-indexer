package db

import (
	"github.com/DefiantLabs/cosmos-indexer/db/models"
	"gorm.io/gorm"
)

func FindOrCreateCustomBlockEventParsers(db *gorm.DB, parsers map[string]models.BlockEventParser) error {
	err := db.Transaction(func(dbTransaction *gorm.DB) error {
		for key := range parsers {
			currParser := parsers[key]
			res := db.FirstOrCreate(&currParser, &currParser)

			if res.Error != nil {
				return res.Error
			}
			parsers[key] = currParser
		}
		return nil
	})
	return err
}

func FindOrCreateCustomMessageParsers(db *gorm.DB, parsers map[string]models.MessageParser) error {
	err := db.Transaction(func(dbTransaction *gorm.DB) error {
		for key := range parsers {
			currParser := parsers[key]
			res := db.FirstOrCreate(&currParser, &currParser)

			if res.Error != nil {
				return res.Error
			}
			parsers[key] = currParser
		}
		return nil
	})
	return err
}

func CreateBlockEventParserError(db *gorm.DB, blockEvent models.BlockEvent, parser models.BlockEventParser, parserError error) error {
	err := db.Transaction(func(dbTransaction *gorm.DB) error {
		res := db.Create(&models.BlockEventParserError{
			BlockEventParser: parser,
			BlockEvent:       blockEvent,
			Error:            parserError.Error(),
		})
		return res.Error
	})
	return err
}

func CreateMessageParserError(db *gorm.DB, message models.Message, parser models.MessageParser, parserError error) error {
	err := db.Transaction(func(dbTransaction *gorm.DB) error {
		res := db.Create(&models.MessageParserError{
			Error:         parserError.Error(),
			MessageParser: parser,
			Message:       message,
		})
		return res.Error
	})
	return err
}
