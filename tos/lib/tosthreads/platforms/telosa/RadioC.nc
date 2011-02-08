
configuration RadioC {

  provides {
    interface BlockingStdControl;
  }

} implementation {

  components
    new BlockingStdControlC(),
    CC2420RadioC;
  BlockingStdControlC.SplitControl -> CC2420RadioC;
  BlockingStdControl = BlockingStdControlC;

}
