module Evergreen.V334.Game exposing (..)

import Array
import Evergreen.V334.Go
import Evergreen.V334.Id
import Evergreen.V334.Message
import Evergreen.V334.SecretId
import Evergreen.V334.UserSession
import Evergreen.V334.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V334.Go.GameMsg
    | GoSetupMsg Evergreen.V334.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V334.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V334.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V334.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V334.Go.ValidatedSetup (Array.Array Evergreen.V334.Go.ActionWithTime) Evergreen.V334.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V334.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V334.WordSpellingGame.ActionWithTime) Evergreen.V334.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V334.SecretId.SecretId Evergreen.V334.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId) (Evergreen.V334.UserSession.ToBeFilledInByBackend (Evergreen.V334.SecretId.SecretId Evergreen.V334.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId) Evergreen.V334.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId) Evergreen.V334.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V334.Go.GameModel
    | WordSpellingGame_Game Evergreen.V334.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V334.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V334.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V334.Go.ValidatedSetup (Array.Array Evergreen.V334.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V334.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V334.WordSpellingGame.ActionWithTime) Evergreen.V334.WordSpellingGame.Shared
