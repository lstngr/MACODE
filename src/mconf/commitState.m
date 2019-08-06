classdef commitState < single
    % COMMITSTATE Status of a mConf commit
    %   Enumartion class indicating whether a mConf object can safely be
    %   commit. It inherits from the single datatype and can thus be mappe
    %   to numerical values.
    %
    %   See also MCONF, SINGLE
    
    enumeration
        % NOTAVAIL - Configuration commit not available
        % The configuration object lacks information, or relies on symbolic
        % expressions to define the magnetic field structure. The commit
        % step cannot be performed as it requires using numerical solvers.
        NotAvail (0)
        
        % AVAIL - Configuration commit available
        % The configuration's magnetic structure is well defined and can be
        % committed safely. If a commit was already requested in the past,
        % the magnetic field seems to have been changed (currents or major
        % radius were modified).
        Avail (1)
        
        % DONE - Commit already performed
        % A commit was already requested in the past, and the magnetic
        % configuration hasn't changed since then.
        Done (2)
    end
end