package gormpsql

import (
	"fmt"

	"github.com/DefiantLabs/cosmos-indexer/config"
	"github.com/DefiantLabs/cosmos-indexer/db"
	"github.com/DefiantLabs/cosmos-indexer/db/models"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

type GormPSQLDatabase struct {
	psqlDB   *gorm.DB
	dbConfig config.Database
}

var _ db.CosmosIndexerDatabase = &GormPSQLDatabase{}

func (g *GormPSQLDatabase) Init(conf config.Database) error {
	g.dbConfig = conf
	return nil
}

func (g *GormPSQLDatabase) Connect() error {
	dsn := fmt.Sprintf("host=%s port=%s dbname=%s user=%s password=%s sslmode=disable", g.dbConfig.Host, g.dbConfig.Port, g.dbConfig.Database, g.dbConfig.User, g.dbConfig.Password)
	gormLogLevel := logger.Silent

	if g.dbConfig.LogLevel == "info" {
		gormLogLevel = logger.Info
	}

	var err error

	g.psqlDB, err = gorm.Open(postgres.Open(dsn), &gorm.Config{Logger: logger.Default.LogMode(gormLogLevel)})

	return err
}

func (g *GormPSQLDatabase) Migrate(models ...any) error {
	return g.psqlDB.AutoMigrate(models...)
}

func (g *GormPSQLDatabase) FindOrCreateCustomBlockEventParsers(map[string]models.BlockEventParser) error {
	return nil
}

func (g *GormPSQLDatabase) FindOrCreateCustomMessageParsers(map[string]models.MessageParser) error {
	return nil
}

func (g *GormPSQLDatabase) CreateBlockEventParserError(blockEvent models.BlockEvent, parser models.BlockEventParser, parserError error) error {
	return nil
}

func (g *GormPSQLDatabase) DeleteCustomBlockEventParserError(blockEvent models.BlockEvent, parser models.BlockEventParser) error {
	return nil
}

func (g *GormPSQLDatabase) CreateCustomMessageParserError(message models.Message, parser models.MessageParser, parserError error) error {
	return nil
}

func (g *GormPSQLDatabase) DeleteCustomMessageParserError(message models.Message, parser models.MessageParser) error {
	return nil
}

func (g *GormPSQLDatabase) GetDBChainID() (any, error) {
	return nil, nil
}

func (g *GormPSQLDatabase) GetHighestIndexedBlock() (models.Block, error) {
	return models.Block{}, nil
}

func (g *GormPSQLDatabase) GetBlocksFromStart(chainID any, startHeight uint64, endHeight uint64) ([]models.Block, error) {
	return []models.Block{}, nil
}

func (g *GormPSQLDatabase) UpsertFailedEventBlock(height uint64, chainID any, chainStringID string) error {
	return nil
}

func (g *GormPSQLDatabase) UpsertFailedBlock(height uint64, chainID any, chainStringID string) error {
	return nil
}

func (g *GormPSQLDatabase) IndexNewBlock(block models.Block, txs []db.TxDBWrapper, indexerConfig config.IndexConfig) (models.Block, []db.TxDBWrapper, error) {
	return models.Block{}, []db.TxDBWrapper{}, nil
}

func (g *GormPSQLDatabase) IndexCustomMessages(conf config.IndexConfig, dryRun bool, blockDBWrapper []db.TxDBWrapper, messageParserTrackers map[string]models.MessageParser) error {
	return nil
}

func (g *GormPSQLDatabase) IndexBlockEvents(dryRun bool, blockDBWrapper *db.BlockDBWrapper, identifierLoggingString string) (*db.BlockDBWrapper, error) {
	return &db.BlockDBWrapper{}, nil
}

func (g *GormPSQLDatabase) IndexCustomBlockEvents(dryRun bool, blockDBWrapper *db.BlockDBWrapper, identifierLoggingString string) (*db.BlockDBWrapper, error) {
	return &db.BlockDBWrapper{}, nil
}
