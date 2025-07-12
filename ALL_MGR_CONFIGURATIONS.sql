SELECT *                                                                                                              
       FROM (SELECT n.node_sid, LEVEL AS lv,                                                                                
                NVL (d.location, 0) LOCATION,                                                                                
                d.longdes LONGDES,
                (select building_id from locationdescription where location = d.location) building_id,
                (select building_name from buildingdescription  where building_id in(select building_id from locationdescription where location = d.location)) building_name,                                                                                          
                d.termid  AS SID,                                                                                            
                t.term_type_sid TERM_TYPE_SID,                                                                              
                n.node_type_sid NODE_TYPE_SID,                                                                              
                LTRIM (SYS_CONNECT_BY_PATH (NVL (d.physical_addr, n.physical_addr),'\'),'\') AS PHYSICAL_ADDR,            
                '(' || CONNECT_BY_ROOT  n.node_sid  || ') ' || CONNECT_BY_ROOT  n.node_num  AS MGR,                          
                CONNECT_BY_ROOT  n.node_sid  AS MGRNODE,                                                                    
                v.version as VERSION,                                                                                        
                n.status as STATUS,                                                                                          
                n.sess_status as SESS_STATUS,                                                                                
                 to_char( n.sess_status_date, 'MM/DD/RRRR HH24:MI:SS' ) as SESS_STATUS_DATE,                                              
                to_char( n.sess_status_date, 'YYYYMMDDHH24MISS' ) as SORTABLE_DATE,                                          
                u.description as DESCRIPTION                                                                                
             FROM DIEBOLD.node n                                                                                            
             LEFT OUTER JOIN (SELECT dd.location, dd.longdes, NVL (m.node_sid, dd.termid) AS termid, m.physical_addr        
                                         FROM    DIEBOLD.locationdescription dd                                          
                                         LEFT OUTER JOIN DIEBOLD.locationaddressmapping m  ON dd.location = m.location      
                              ) d ON d.termid = n.node_sid                                                  
             LEFT OUTER JOIN DIEBOLD.node_type_term t                                                                        
                ON t.node_sid = n.node_sid                                                                                  
             LEFT OUTER JOIN (SELECT * FROM DIEBOLD.uilistvalues                                                            
                               WHERE field = 'TerminalStatus' AND groupid = -1) u                                            
                ON n.sess_status = u.VALUE                                                                                  
             LEFT OUTER JOIN (SELECT UNIQUE node_sid, location, FIRST_VALUE (version)                                        
                                                                OVER (PARTITION BY node_sid,                                
                                                                                location ORDER BY postdate DESC) AS version  
                                FROM DIEBOLD.readerversion) v                                                                
                 ON v.location = d.location                                                                                  
                AND v.node_sid = d.termid                                                                                    
             WHERE (t.term_type_sid <> 2026                                                                                  
                        OR (t.term_type_sid = 2026                                                                          
                       AND NOT EXISTS (SELECT 1 FROM DIEBOLD.node a                                                          
                                       WHERE a.node_sid = n.parent_node_sid                                                  
                                         AND 3 = (SELECT node_type_sid FROM DIEBOLD.node b                                  
                                                   WHERE b.node_sid = a.parent_node_sid))))                      
             START WITH (n.node_type_sid = 1) CONNECT BY PRIOR n.node_sid = n.parent_node_sid                                
            ORDER SIBLINGS BY d.location)                                                                                    
       WHERE NODE_TYPE_SID = 3                                                                                              
         AND LOCATION <> 0  
         and status = 'ACT'                                                                                              
         order by location