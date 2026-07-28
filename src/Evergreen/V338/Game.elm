module Evergreen.V338.Game exposing (..)

import Array
import Evergreen.V338.Go
import Evergreen.V338.Id
import Evergreen.V338.Message
import Evergreen.V338.SecretId
import Evergreen.V338.UserSession
import Evergreen.V338.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V338.Go.GameMsg
    | GoSetupMsg Evergreen.V338.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V338.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V338.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V338.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V338.Go.ValidatedSetup (Array.Array Evergreen.V338.Go.ActionWithTime) Evergreen.V338.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V338.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V338.WordSpellingGame.ActionWithTime) Evergreen.V338.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V338.SecretId.SecretId Evergreen.V338.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) (Evergreen.V338.UserSession.ToBeFilledInByBackend (Evergreen.V338.SecretId.SecretId Evergreen.V338.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) Evergreen.V338.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) Evergreen.V338.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V338.Go.GameModel
    | WordSpellingGame_Game Evergreen.V338.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V338.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V338.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V338.Go.ValidatedSetup (Array.Array Evergreen.V338.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V338.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V338.WordSpellingGame.ActionWithTime) Evergreen.V338.WordSpellingGame.Shared
