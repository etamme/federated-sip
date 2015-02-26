--
-- Table structure for table `translations`
--
DROP TABLE IF EXISTS `translations`;
CREATE TABLE `translations` (
  `from_username` char(64) DEFAULT NULL,
  `from_domain` char(64) DEFAULT NULL,
  `match_regex` char(64) DEFAULT NULL,
  `tran_strip` int(10) DEFAULT NULL,
  `tran_prefix` char(64) DEFAULT NULL,
  `tran_user` char(64) DEFAULT NULL,
  `tran_domain` char(64) DEFAULT NULL,
  `tran_add_header` char(255) DEFAULT NULL,
  `tran_priority` int(10) NOT NULL DEFAULT '99',
  KEY `from_username` (`from_username`,`from_domain`,`match_regex`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
