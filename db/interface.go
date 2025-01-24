package db

import (
	"github.com/DefiantLabs/cosmos-indexer/config"
	"github.com/DefiantLabs/cosmos-indexer/db/models"
)

type CosmosIndexerDatabase interface {
	Init(config.Database) error
	Connect() error
	Migrate(...any) error
	FindOrCreateCustomBlockEventParsers(map[string]models.BlockEventParser) error
	FindOrCreateCustomMessageParsers(map[string]models.MessageParser) error
	CreateBlockEventParserError(blockEvent models.BlockEvent, parser models.BlockEventParser, parserError error) error
	DeleteCustomBlockEventParserError(blockEvent models.BlockEvent, parser models.BlockEventParser) error
	CreateCustomMessageParserError(message models.Message, parser models.MessageParser, parserError error) error
	DeleteCustomMessageParserError(message models.Message, parser models.MessageParser) error
	GetDBChainID() (any, error)
	GetHighestIndexedBlock() (models.Block, error)
	GetBlocksFromStart(chainID any, startHeight uint64, endHeight uint64) ([]models.Block, error)
	UpsertFailedEventBlock(height uint64, chainID any, chainStringID string) error
	UpsertFailedBlock(height uint64, chainID any, chainStringID string) error
	IndexNewBlock(block models.Block, txs []TxDBWrapper, indexerConfig config.IndexConfig) (models.Block, []TxDBWrapper, error)
	IndexCustomMessages(conf config.IndexConfig, dryRun bool, blockDBWrapper []TxDBWrapper, messageParserTrackers map[string]models.MessageParser) error
	IndexBlockEvents(dryRun bool, blockDBWrapper *BlockDBWrapper, identifierLoggingString string) (*BlockDBWrapper, error)
	IndexCustomBlockEvents(dryRun bool, blockDBWrapper *BlockDBWrapper, identifierLoggingString string) (*BlockDBWrapper, error)
}
