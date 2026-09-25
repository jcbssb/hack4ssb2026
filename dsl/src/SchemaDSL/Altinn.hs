module SchemaDSL.Altinn
  ( AltinnArtifacts(..)
  , compileToAltinn
  , injectIntoAltinnApp
  , injectIntoAltinnAppPaged
  , compileToAltinnPaged
  , pageName
  , pageLayout
  , enforceEvolutionPageOrder
  , isOwnPage
  , updateSettingsPageOrder
  , stripBOM
  , compileSteps
  , compilePredicateToHidden
  ) where

import SchemaDSL.Altinn.Types (AltinnArtifacts(..), pageName, pageLayout)
import SchemaDSL.Altinn.Compile (compileToAltinn, compileToAltinnPaged, compileSteps, compilePredicateToHidden)
import SchemaDSL.Altinn.Inject (injectIntoAltinnApp, injectIntoAltinnAppPaged, isOwnPage, enforceEvolutionPageOrder, updateSettingsPageOrder, stripBOM)
