module Evergreen.V343.Game exposing (..)

import Array
import Evergreen.V343.Go
import Evergreen.V343.Id
import Evergreen.V343.Message
import Evergreen.V343.SecretId
import Evergreen.V343.UserSession
import Evergreen.V343.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V343.Go.GameMsg
    | GoSetupMsg Evergreen.V343.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V343.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V343.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V343.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V343.Go.ValidatedSetup (Array.Array Evergreen.V343.Go.ActionWithTime) Evergreen.V343.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V343.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V343.WordSpellingGame.ActionWithTime) Evergreen.V343.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V343.SecretId.SecretId Evergreen.V343.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) (Evergreen.V343.UserSession.ToBeFilledInByBackend (Evergreen.V343.SecretId.SecretId Evergreen.V343.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) Evergreen.V343.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) Evergreen.V343.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V343.Go.GameModel
    | WordSpellingGame_Game Evergreen.V343.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V343.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V343.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V343.Go.ValidatedSetup (Array.Array Evergreen.V343.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V343.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V343.WordSpellingGame.ActionWithTime) Evergreen.V343.WordSpellingGame.Shared
