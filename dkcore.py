#!ipy
#
# Copyright (c) 2009 SteelEye Technology Inc.  All rights reserved.
#
# IronPython (ipy) "boot" module to load SDR assmeblies and import stuff that we'll use a lot.
# This should be used/imported while sitting in the directory that contains the dlls mentioned
# below (the snap-in bin directory usually).
#
# Change   Description                                                           By    Date
# ----------------------------------------------------------------------------------------------
# 0001     bug722: refactor relationship functions into RelationshipUtils       STT  11-16-2009
# 0002     ?       Other changes related to relationship calculations           STT  12-15-2009
# 0004     bug781: Modifications for state update performance                   STT  12-15-2009
# 0005     bug3167: Changed during unit test writing - was a little out of date STT  06-07-2013
#

# 0005 - changed to reference-by-name for newer ironpython versions.
import clr
clr.AddReference('SDRClient')
clr.AddReference('SDRService')
clr.AddReference('SteelEye.DataKeeper.Api')
clr.AddReference('log4net')

# These are imported and aliased one at a time to make it clear
# which types are being imported from the assemblies under test.
from System.IO import File
import System.Collections.Generic.List as List
import SDRClient.EmService as EmService
import SDRClient.EmVolumeInfo as EmVolumeInfo
import SDRClient.ClientLibEmService as ClientLibEmService
import SteelEye.Model.DataReplication.Job as Job
import SteelEye.Model.DataReplication.Job as Job
import SteelEye.Model.DataReplication.JobVolume as JobVolume
import SteelEye.Model.DataReplication.EndpointPair as EndpointPair
import SteelEye.Model.DataReplication.ServiceInfo as ServiceInfo
import SteelEye.Model.DataReplication.VolumeInfo as VolumeInfo
import SteelEye.Model.DataReplication.TargetInfo as TargetInfo
import SteelEye.Model.DataReplication.ResyncStatus as ResyncStatus
import SteelEye.Model.DataReplication.RewindConfig as RewindConfig
import SteelEye.Model.DataReplication.RewindStatus as RewindStatus
import SteelEye.Model.DataReplication.MirrorType as MirrorType
import SteelEye.Model.DataReplication.MirrorState as MirrorState
import SteelEye.Model.DataReplication.MirrorRole as MirrorRole
import SteelEye.Model.DataReplication.TimeRange as TimeRange
import SteelEye.Model.DataReplication.TimeBookmark as TimeBookmark
import SteelEye.DAO.DataReplication.EmServiceFactory as EmServiceFactory
import SteelEye.DAO.Impl.DataReplication.ClientLibEmServiceSingletonFactory as ClientLibEmServiceSingletonFactory
import SteelEye.DAO.Impl.DataReplication.ClientLibEmServicePrototypeFactory as ClientLibEmServicePrototypeFactory
import SteelEye.DAO.DataReplication.MirrorCreateOptions as MirrorCreateOptions
import SteelEye.DAO.DataReplication.SDRService as SDRService
import SteelEye.DAO.Impl.DataReplication.ClientLibrarySDRService as ClientLibrarySDRService
import SteelEye.DAO.Impl.DataReplication.CachingSDRService as CachingSDRService
import SteelEye.DAO.Impl.DataReplication.JobExtractor as JobExtractor
import SteelEye.DAO.DataReplication.Exception.InvalidRewindTimestampException as InvalidRewindTimestampException
import SteelEye.DAO.DataReplication.Exception.RewindFlushPointMatchException as RewindFlushPointMatchException
import SteelEye.DAO.DataReplication.Exception.RewindNotCompletelyEnabledException as RewindNotCompletelyEnabledException
import SteelEye.DAO.DataReplication.Exception.RewindVolumeDirtyException as RewindVolumeDirtyException
import SteelEye.DAO.DataReplication.Exception.ServiceNoLongerAvailableException as ServiceNoLongerAvailableException
import SteelEye.DAO.DataReplication.Exception.ServiceNotFoundException as ServiceNotFoundException
import SteelEye.DAO.DataReplication.Exception.ServiceTooBusyException as ServiceTooBusyException
import SteelEye.DAO.DataReplication.Exception.UnknownRewindFailureException as UnknownRewindFailureException
import SteelEye.Util.IPUtils as IPUtils
import SteelEye.DataKeeper.DataKeeperService as DataKeeperService
import SteelEye.DataKeeper.RelationshipUtils as RelationshipUtils
import SteelEye.DataKeeper.ConnectionPair as ConnectionPair
import SteelEye.DataKeeper.IJob as IJob
import SteelEye.DataKeeper.IMirror as IMirror
import SteelEye.DataKeeper.IServer as IServer
import SteelEye.DataKeeper.IVolume as IVolume
import SteelEye.DataKeeper.MirrorContainerStatus as MirrorContainerStatus
import SteelEye.DataKeeper.NetworkConnection as NetworkConnection
import SteelEye.DataKeeper.ServiceInformation as MirrorContainerStatus
import SteelEye.DataKeeper.SDR.SDRDataKeeperService as SDRDataKeeperService
import SteelEye.DataKeeper.SDR.Job as DKJob
import SteelEye.DataKeeper.SDR.Mirror as DKMirror
import SteelEye.DataKeeper.SDR.Server as DKServer
import SteelEye.DataKeeper.SDR.Volume as DKVolume
import System.Exception as Exception
from log4net import LogManager
from log4net.Config import XmlConfigurator

# Some logging setup
logConfigStream = File.OpenRead('Logging.Test.xml')
XmlConfigurator.Configure(logConfigStream)

# Now make a service instance
sdrsvc      = ClientLibrarySDRService(ClientLibEmServiceSingletonFactory())
sdrclient   = ClientLibEmServiceSingletonFactory().GetInstance()
cachingsvc  = CachingSDRService(sdrsvc, CachingSDRService.NormalCacher)
extractor   = JobExtractor(cachingsvc)
dksvc       = DataKeeperService.Instance

