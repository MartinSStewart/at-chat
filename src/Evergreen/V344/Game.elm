module Evergreen.V344.Game exposing (..)

import Array
import Evergreen.V344.Go
import Evergreen.V344.Id
import Evergreen.V344.Message
import Evergreen.V344.SecretId
import Evergreen.V344.UserSession
import Evergreen.V344.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V344.Go.GameMsg
    | GoSetupMsg Evergreen.V344.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V344.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V344.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V344.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V344.Go.ValidatedSetup (Array.Array Evergreen.V344.Go.ActionWithTime) Evergreen.V344.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V344.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V344.WordSpellingGame.ActionWithTime) Evergreen.V344.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V344.SecretId.SecretId Evergreen.V344.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) (Evergreen.V344.UserSession.ToBeFilledInByBackend (Evergreen.V344.SecretId.SecretId Evergreen.V344.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) Evergreen.V344.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) Evergreen.V344.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V344.Go.GameModel
    | WordSpellingGame_Game Evergreen.V344.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V344.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V344.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V344.Go.ValidatedSetup (Array.Array Evergreen.V344.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V344.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V344.WordSpellingGame.ActionWithTime) Evergreen.V344.WordSpellingGame.Shared
